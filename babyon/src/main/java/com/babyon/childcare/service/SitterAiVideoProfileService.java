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
    private final S3Service s3Service;

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

        // 4. 영상 길이 검증 (현재: 파일 크기 기반 추정, FUTURE: FFmpeg 통합)
        Integer introDuration = extractVideoDuration(request.getIntroVideo());
        Integer answerDuration = extractVideoDuration(request.getAnswerVideo());

        validateVideoDuration(introDuration, "Intro Video");
        validateVideoDuration(answerDuration, "Answer Video");

        // 5. S3에 영상 파일 업로드
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

        AiProfileResponse response = AiProfileResponse.fromEntity(profile);
        
        // S3 키를 Presigned URL로 변환 (1시간 유효)
        if (response.getIntroVideoUrl() != null) {
            response.setIntroVideoUrl(s3Service.generatePresignedUrl(response.getIntroVideoUrl()));
        }
        if (response.getAnswerVideoUrl() != null) {
            response.setAnswerVideoUrl(s3Service.generatePresignedUrl(response.getAnswerVideoUrl()));
        }
        
        return response;
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
     * 영상 길이 추출 (임시 구현: 파일 크기 기반 추정)
     *
     * FUTURE ENHANCEMENT: FFmpeg 또는 Xuggler를 사용한 정확한 영상 메타데이터 추출
     *
     * 현재는 파일 크기 기반으로 보수적으로 추정하여 최대 길이 검증만 수행
     * 추정 기준: 1MB ≈ 10초 (매우 보수적 - 실제는 더 짧을 수 있음)
     * 이는 고화질 영상 기준이며, 악의적 대용량 파일 업로드를 방지하기 위한 임시 조치
     */
    private Integer extractVideoDuration(MultipartFile videoFile) {
        // 파일 크기 기반 최대 추정 길이 계산
        long fileSizeInMB = videoFile.getSize() / (1024 * 1024);
        int estimatedMaxSeconds = (int) (fileSizeInMB * 10); // 1MB당 10초로 보수적 추정

        // 추정된 최대 길이가 제한을 초과하는 경우 사전 차단
        if (estimatedMaxSeconds > MAX_VIDEO_DURATION_SECONDS) {
            log.warn("Video file size suggests duration exceeds limit. " +
                    "File size: {}MB, Estimated max duration: {}s, Limit: {}s",
                    fileSizeInMB, estimatedMaxSeconds, MAX_VIDEO_DURATION_SECONDS);

            throw new VideoDurationExceededException(
                    videoFile.getOriginalFilename(),
                    MAX_VIDEO_DURATION_SECONDS,
                    estimatedMaxSeconds
            );
        }

        log.warn("Video duration extraction not fully implemented - using file size based estimation. " +
                "Actual duration verification will be available after FFmpeg integration.");

        // 실제 FFmpeg 구현 전까지는 null 반환 (추정치는 검증에만 사용)
        // 향후 구현 예시:
        // FFmpegFrameGrabber grabber = new FFmpegFrameGrabber(videoFile.getInputStream());
        // grabber.start();
        // int duration = (int) (grabber.getLengthInTime() / 1_000_000); // microseconds to seconds
        // grabber.stop();
        // return duration;

        return null;
    }

    /**
     * S3에 영상 업로드
     * AWS S3 SDK를 사용한 파일 업로드
     */
    private String uploadVideoToS3(MultipartFile videoFile, Long sitterId, String videoType) {
        String folder = String.format("sitter/%d/ai-profile", sitterId);
        String s3Key = s3Service.uploadFile(videoFile, folder);
        
        log.info("Video uploaded to S3: sitterId={}, videoType={}, s3Key={}", 
                sitterId, videoType, s3Key);
        
        return s3Key;
    }
}
