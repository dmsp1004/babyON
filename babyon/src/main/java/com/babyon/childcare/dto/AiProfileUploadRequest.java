package com.babyon.childcare.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

/**
 * AI 화상 이력서 업로드 요청 DTO
 * 시터가 자유 소개 영상과 AI 질문 답변 영상을 업로드할 때 사용
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiProfileUploadRequest {

    /**
     * 자유 소개 영상 파일 (최대 120초)
     */
    @NotNull(message = "Intro video is required")
    private MultipartFile introVideo;

    /**
     * AI 질문 답변 영상 파일 (최대 120초)
     */
    @NotNull(message = "Answer video is required")
    private MultipartFile answerVideo;

    /**
     * 답변한 AI 질문 ID
     */
    @NotNull(message = "AI question ID is required")
    @Positive(message = "AI question ID must be positive")
    private Long aiQuestionId;

    /**
     * 프로필 상태 (선택 사항)
     * PENDING, ACTIVE, INACTIVE, REVIEWING 중 하나
     */
    @Pattern(regexp = "PENDING|ACTIVE|INACTIVE|REVIEWING", message = "Invalid status. Must be one of: PENDING, ACTIVE, INACTIVE, REVIEWING")
    private String status; // Optional: 기본값은 PENDING
}
