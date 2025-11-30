package com.babyon.childcare.dto;

import com.babyon.childcare.entity.SitterAiVideoProfile;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * AI 화상 이력서 응답 DTO
 * 시터의 AI 화상 이력서 조회 시 반환되는 데이터
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiProfileResponse {

    private Long sitterId;
    private String introVideoUrl;
    private Integer introVideoDurationSeconds;
    private AiQuestionResponse aiQuestion; // 답변한 질문 정보
    private String answerVideoUrl;
    private Integer answerVideoDurationSeconds;
    private String status;
    private Integer viewCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * Entity -> DTO 변환
     */
    public static AiProfileResponse fromEntity(SitterAiVideoProfile profile) {
        return AiProfileResponse.builder()
                .sitterId(profile.getSitterId())
                .introVideoUrl(profile.getIntroVideoUrl())
                .introVideoDurationSeconds(profile.getIntroVideoDurationSeconds())
                .aiQuestion(profile.getAiQuestion() != null ?
                        AiQuestionResponse.fromEntity(profile.getAiQuestion()) : null)
                .answerVideoUrl(profile.getAnswerVideoUrl())
                .answerVideoDurationSeconds(profile.getAnswerVideoDurationSeconds())
                .status(profile.getStatus() != null ? profile.getStatus().name() : null)
                .viewCount(profile.getViewCount())
                .createdAt(profile.getCreatedAt())
                .updatedAt(profile.getUpdatedAt())
                .build();
    }
}
