package com.babyon.childcare.dto;

import com.babyon.childcare.entity.AiQuestion;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * AI 질문 응답 DTO
 * 랜덤 질문 조회 시 반환되는 데이터
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiQuestionResponse {

    private Long questionId;
    private String questionText;
    private String questionCategory;
    private String difficultyLevel;
    private Integer timeLimitSeconds; // 녹화 시간 제한 (기본 120초)

    /**
     * Entity -> DTO 변환
     */
    public static AiQuestionResponse fromEntity(AiQuestion aiQuestion) {
        return AiQuestionResponse.builder()
                .questionId(aiQuestion.getId())
                .questionText(aiQuestion.getQuestionText())
                .questionCategory(aiQuestion.getQuestionCategory() != null ?
                        aiQuestion.getQuestionCategory().name() : null)
                .difficultyLevel(aiQuestion.getDifficultyLevel() != null ?
                        aiQuestion.getDifficultyLevel().name() : null)
                .timeLimitSeconds(aiQuestion.getTimeLimitSeconds())
                .build();
    }
}
