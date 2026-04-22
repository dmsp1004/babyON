package com.babyon.childcare.service;

import com.babyon.childcare.dto.AiAnalysisResult;
import com.babyon.childcare.entity.SitterAiVideoProfile;
import com.babyon.childcare.repository.SitterAiVideoProfileRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * AI 영상 분석 비동기 서비스
 *
 * S3 업로드 완료 직후 {@link SitterAiVideoProfileService}에서 호출된다.
 * 분석은 별도 스레드(aiAnalysisExecutor)에서 실행되므로 업로드 응답을 블로킹하지 않는다.
 *
 * ── 연동 순서 (향후) ──────────────────────────────
 *  1. S3 presigned URL → 외부 AI API 전달 (Whisper STT, GPT-4o 등)
 *  2. API 응답 수신 → AiAnalysisResult 매핑
 *  3. JSON 직렬화 → DB 저장 + 상태 ACTIVE 전환
 * ──────────────────────────────────────────────────
 *
 * 현재는 stub 분석 결과를 생성하며, 실제 API 연동 준비가 완료되면
 * {@link #callExternalAiApi} 메서드만 교체하면 된다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AiAnalysisService {

    private final SitterAiVideoProfileRepository aiVideoProfileRepository;
    private final S3Service s3Service;
    private final ObjectMapper objectMapper;

    @Value("${app.ai.analysis.enabled:false}")
    private boolean aiAnalysisEnabled;

    @Value("${app.ai.analysis.version:stub-1.0}")
    private String analysisVersion;

    /**
     * S3 업로드 완료 후 AI 분석을 비동기로 트리거한다.
     *
     * @param sitterId         분석 대상 시터 ID
     * @param introVideoS3Key  인트로 영상 S3 키
     * @param answerVideoS3Key 답변 영상 S3 키
     */
    @Async("aiAnalysisExecutor")
    @Transactional
    public void triggerAnalysis(Long sitterId, String introVideoS3Key, String answerVideoS3Key) {
        log.info("[AI Analysis] 분석 시작: sitterId={}", sitterId);

        SitterAiVideoProfile profile = aiVideoProfileRepository.findBySitterId(sitterId)
                .orElse(null);

        if (profile == null) {
            log.warn("[AI Analysis] 프로필을 찾을 수 없어 분석을 건너뜁니다: sitterId={}", sitterId);
            return;
        }

        // 분석 중 상태로 전환 (중복 실행 방지)
        if (profile.getStatus() == SitterAiVideoProfile.ProfileStatus.ANALYZING) {
            log.warn("[AI Analysis] 이미 분석 중인 프로필입니다: sitterId={}", sitterId);
            return;
        }
        profile.setStatus(SitterAiVideoProfile.ProfileStatus.ANALYZING);
        aiVideoProfileRepository.save(profile);

        try {
            AiAnalysisResult result = aiAnalysisEnabled
                    ? callExternalAiApi(sitterId, introVideoS3Key, answerVideoS3Key)
                    : buildStubResult(sitterId);

            saveAnalysisResult(profile, result);
            log.info("[AI Analysis] 분석 완료: sitterId={}, score={}, recommendation={}",
                    sitterId, result.getOverallScore(), result.getRecommendation());

        } catch (Exception e) {
            log.error("[AI Analysis] 분석 실패: sitterId={}", sitterId, e);
            saveAnalysisError(profile, e.getMessage());
        }
    }

    // ──────────────────────────────────────────────────
    // 외부 AI API 호출 (실제 연동 시 이 메서드를 구현한다)
    // ──────────────────────────────────────────────────

    /**
     * 외부 AI API를 호출하여 분석 결과를 반환한다.
     *
     * TODO: 아래 구현 단계에 따라 교체한다.
     *   1단계: AWS Transcribe / Whisper API로 STT 텍스트 추출
     *   2단계: 추출된 텍스트를 GPT-4o API에 전달하여 키워드·감정·전문성 분석
     *   3단계: 분석 결과를 AiAnalysisResult에 매핑하여 반환
     *
     * 연동 예시 (Whisper):
     *   String presignedUrl = s3Service.generatePresignedUrl(introVideoS3Key);
     *   WhisperResponse stt = whisperClient.transcribe(presignedUrl);
     *   GptResponse gpt = gptClient.analyze(stt.getText(), questionText);
     *   return mapToResult(gpt);
     */
    private AiAnalysisResult callExternalAiApi(
            Long sitterId, String introVideoS3Key, String answerVideoS3Key) {

        // 실제 연동 전까지는 stub 반환 (aiAnalysisEnabled=true여도 안전하게 동작)
        log.warn("[AI Analysis] 외부 AI API 미연동 — stub 결과를 반환합니다: sitterId={}", sitterId);
        return buildStubResult(sitterId);
    }

    // ──────────────────────────────────────────────────
    // Stub 분석 결과 (외부 API 연동 전 임시 사용)
    // ──────────────────────────────────────────────────

    private AiAnalysisResult buildStubResult(Long sitterId) {
        log.debug("[AI Analysis] stub 분석 결과 생성: sitterId={}", sitterId);
        return AiAnalysisResult.builder()
                .overallScore(0.75)
                .keywords(List.of("성실함", "친절함", "경험 보유"))
                .sentimentScore(0.80)
                .communicationScore(0.70)
                .professionalismScore(0.75)
                .recommendation("APPROVED")
                .analysisVersion(analysisVersion)
                .build();
    }

    // ──────────────────────────────────────────────────
    // DB 저장 헬퍼
    // ──────────────────────────────────────────────────

    private void saveAnalysisResult(SitterAiVideoProfile profile, AiAnalysisResult result) {
        try {
            String resultJson = objectMapper.writeValueAsString(result);
            profile.setAiAnalysisResult(resultJson);
            profile.setAiAnalyzedAt(LocalDateTime.now());

            // 추천 결과에 따라 상태 전환
            SitterAiVideoProfile.ProfileStatus nextStatus =
                    "REJECTED".equals(result.getRecommendation())
                            ? SitterAiVideoProfile.ProfileStatus.INACTIVE
                            : "REVIEW_NEEDED".equals(result.getRecommendation())
                                    ? SitterAiVideoProfile.ProfileStatus.REVIEWING
                                    : SitterAiVideoProfile.ProfileStatus.ACTIVE;

            profile.setStatus(nextStatus);
            aiVideoProfileRepository.save(profile);

        } catch (Exception e) {
            log.error("[AI Analysis] 결과 저장 실패: sitterId={}", profile.getSitterId(), e);
            saveAnalysisError(profile, "결과 직렬화 실패: " + e.getMessage());
        }
    }

    private void saveAnalysisError(SitterAiVideoProfile profile, String errorMessage) {
        try {
            AiAnalysisResult errorResult = AiAnalysisResult.builder()
                    .recommendation("REVIEW_NEEDED")
                    .analysisVersion(analysisVersion)
                    .errorReason(errorMessage)
                    .build();

            profile.setAiAnalysisResult(objectMapper.writeValueAsString(errorResult));
            profile.setAiAnalyzedAt(LocalDateTime.now());
            profile.setStatus(SitterAiVideoProfile.ProfileStatus.REVIEWING);
            aiVideoProfileRepository.save(profile);
        } catch (Exception ex) {
            log.error("[AI Analysis] 오류 상태 저장도 실패: sitterId={}", profile.getSitterId(), ex);
        }
    }
}
