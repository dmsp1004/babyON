package com.babyon.childcare.service;

import com.babyon.childcare.dto.AiProfileResponse;
import com.babyon.childcare.dto.AiProfileUploadRequest;
import com.babyon.childcare.dto.AiQuestionResponse;
import com.babyon.childcare.entity.AiQuestion;
import com.babyon.childcare.entity.Sitter;
import com.babyon.childcare.entity.SitterAiVideoProfile;
import com.babyon.childcare.exception.*;
import com.babyon.childcare.repository.AiQuestionRepository;
import com.babyon.childcare.repository.SitterAiVideoProfileRepository;
import com.babyon.childcare.repository.SitterRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.Arrays;
import java.util.List;
import java.util.Random;

/**
 * 시터 AI 화상 이력서 Service
 * AI 질문 랜덤 선택, 영상 업로드, 검증 등의 비즈니스 로직 처리
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SitterAiVideoProfileService {

    private final SitterAiVideoProfileRepository aiVideoProfileRepository;
    private final AiQuestionRepository aiQuestionRepository;
    private final SitterRepository sitterRepository;

    // TODO: S3 Service 의존성 추가 필요
    // private final S3Service s3Service;

    private static final int MAX_VIDEO_DURATION_SECONDS = 120; // 최대 영상 길이: 120초
    private static final long MAX_VIDEO_FILE_SIZE_BYTES = 100 * 1024 * 1024; // 최대 파일 크기: 100MB
    private static final int RANDOM_QUESTION_SAMPLE_SIZE = 10; // 랜덤 질문 샘플 크기

    /**
     * 랜덤 AI 질문 조회
     * 사용 횟수가 적은 질문을 우선적으로 선택하여 질문 분배를 균등하게 함
     */
    public AiQuestionResponse getRandomQuestion() {
        List<AiQuestion> activeQuestions = aiQuestionRepository.findActiveQuestionsOrderByUsageCount();

        if (activeQuestions.isEmpty()) {
            throw new AiQuestionNotFoundException("No active AI questions available");
        }

        // 사용 횟수가 가장 적은 상위 N개 중에서 랜덤 선택
        int sampleSize = Math.min(RANDOM_QUESTION_SAMPLE_SIZE, activeQuestions.size());
        List<AiQuestion> topQuestions = activeQuestions.subList(0, sampleSize);

        Random random = new Random();
        AiQuestion selectedQuestion = topQuestions.get(random.nextInt(topQuestions.size()));

        log.info("Selected random AI question: ID={}, Category={}",
                selectedQuestion.getId(), selectedQuestion.getQuestionCategory());

        return AiQuestionResponse.fromEntity(selectedQuestion);
    }

    /**
     * AI 화상 이력서 업로드/업데이트
     * 두 개의 영상 파일(인트로, 답변)을 S3에 업로드하고 DB에 저장
     */
    @Transactional
    public AiProfileResponse uploadOrUpdateProfile(Long sitterId, AiProfileUploadRequest request) {
        // 1. 시터 존재 여부 확인
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new SitterNotFoundException(sitterId));

        // 2. AI 질문 존재 여부 확인
        AiQuestion aiQuestion = aiQuestionRepository.findByIdAndIsActiveTrue(request.getAiQuestionId())
                .orElseThrow(() -> new AiQuestionNotFoundException(request.getAiQuestionId()));

        // 3. 파일 검증
        validateVideoFile(request.getIntroVideo(), "Intro Video");
        validateVideoFile(request.getAnswerVideo(), "Answer Video");

        // 4. 영상 길이 검증 (TODO: 실제 구현 시 FFmpeg 등을 사용하여 영상 메타데이터 추출)
        Integer introDuration = extractVideoDuration(request.getIntroVideo());
        Integer answerDuration = extractVideoDuration(request.getAnswerVideo());

        validateVideoDuration(introDuration, "Intro Video");
        validateVideoDuration(answerDuration, "Answer Video");

        // 5. S3에 영상 파일 업로드 (TODO: 실제 S3Service 구현 필요)
        String introVideoUrl = uploadVideoToS3(request.getIntroVideo(), sitterId, "intro");
        String answerVideoUrl = uploadVideoToS3(request.getAnswerVideo(), sitterId, "answer");

        // 6. 기존 프로필 조회 또는 새로 생성
        SitterAiVideoProfile profile = aiVideoProfileRepository.findBySitterId(sitterId)
                .orElse(new SitterAiVideoProfile());

        // 7. 프로필 데이터 업데이트
        profile.setSitterId(sitterId);
        profile.setSitter(sitter);
        profile.setIntroVideoUrl(introVideoUrl);
        profile.setIntroVideoDurationSeconds(introDuration);
        profile.setAiQuestion(aiQuestion);
        profile.setAnswerVideoUrl(answerVideoUrl);
        profile.setAnswerVideoDurationSeconds(answerDuration);

        // 상태 설정 (요청에 상태가 있으면 사용, 없으면 PENDING)
        if (request.getStatus() != null) {
            profile.setStatus(SitterAiVideoProfile.ProfileStatus.valueOf(request.getStatus()));
        } else if (profile.getStatus() == null) {
            profile.setStatus(SitterAiVideoProfile.ProfileStatus.PENDING);
        }

        // 8. DB 저장
        SitterAiVideoProfile savedProfile = aiVideoProfileRepository.save(profile);

        // 9. AI 질문 사용 횟수 증가
        aiQuestion.setUsageCount(aiQuestion.getUsageCount() + 1);
        aiQuestionRepository.save(aiQuestion);

        log.info("AI video profile uploaded successfully for sitter: {}", sitterId);

        return AiProfileResponse.fromEntity(savedProfile);
    }

    /**
     * AI 화상 이력서 조회
     */
    public AiProfileResponse getProfile(Long sitterId) {
        SitterAiVideoProfile profile = aiVideoProfileRepository.findBySitterId(sitterId)
                .orElseThrow(() -> new ProfileNotFoundException(sitterId));

        return AiProfileResponse.fromEntity(profile);
    }

    /**
     * 시터 ID로 AI 화상 이력서 존재 여부 확인
     */
    public boolean hasProfile(Long sitterId) {
        return aiVideoProfileRepository.existsBySitterId(sitterId);
    }

    // ========================= Private Helper Methods =========================

    /**
     * 비디오 파일 기본 검증 (null 체크, 파일 크기 체크)
     */
    private void validateVideoFile(MultipartFile file, String fileName) {
        if (file == null || file.isEmpty()) {
            throw new InvalidFileException(fileName + " is required and cannot be empty");
        }

        if (file.getSize() > MAX_VIDEO_FILE_SIZE_BYTES) {
            throw new FileSizeExceededException(fileName, MAX_VIDEO_FILE_SIZE_BYTES);
        }

        // 비디오 파일 형식 체크 (간단한 MIME 타입 체크)
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("video/")) {
            throw new InvalidFileTypeException(fileName, "video");
        }
    }

    /**
     * 영상 길이 검증 (최대 120초)
     */
    private void validateVideoDuration(Integer durationSeconds, String fileName) {
        if (durationSeconds == null) {
            log.warn("{} duration could not be extracted, skipping duration validation", fileName);
            return;
        }

        if (durationSeconds > MAX_VIDEO_DURATION_SECONDS) {
            throw new VideoDurationExceededException(fileName, MAX_VIDEO_DURATION_SECONDS, durationSeconds);
        }
    }

    /**
     * 영상 길이 추출 (TODO: 실제 구현 필요)
     * 실제 구현 시 FFmpeg 또는 Xuggler 등을 사용하여 영상 메타데이터 추출
     */
    private Integer extractVideoDuration(MultipartFile videoFile) {
        // TODO: FFmpeg 또는 Xuggler를 사용하여 실제 영상 길이 추출
        // 예시:
        // FFmpegFrameGrabber grabber = new FFmpegFrameGrabber(videoFile.getInputStream());
        // grabber.start();
        // int duration = (int) (grabber.getLengthInTime() / 1_000_000); // microseconds to seconds
        // grabber.stop();
        // return duration;

        log.warn("Video duration extraction not implemented yet - returning null");
        return null; // 임시로 null 반환 (검증 스킵)
    }

    /**
     * S3에 영상 업로드 (TODO: 실제 구현 필요)
     * 실제 구현 시 AWS S3 SDK를 사용하여 파일 업로드
     */
    private String uploadVideoToS3(MultipartFile videoFile, Long sitterId, String videoType) {
        // TODO: 실제 S3Service를 통한 파일 업로드 구현
        // 예시:
        // String fileName = String.format("sitter/%d/ai-profile/%s-%d.mp4",
        //         sitterId, videoType, System.currentTimeMillis());
        // return s3Service.uploadFile(videoFile, fileName);

        String mockUrl = String.format("https://s3.amazonaws.com/babyon/sitter/%d/ai-profile/%s-%d.mp4",
                sitterId, videoType, System.currentTimeMillis());

        log.warn("S3 upload not implemented yet - returning mock URL: {}", mockUrl);
        return mockUrl; // 임시로 Mock URL 반환
    }
}
