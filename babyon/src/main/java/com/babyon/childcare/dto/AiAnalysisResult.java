package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * AI 분석 결과 DTO — SitterAiVideoProfile.aiAnalysisResult 컬럼에 JSON으로 직렬화된다.
 *
 * 외부 AI API 연동 시 이 클래스의 필드를 실제 응답에 맞게 매핑한다.
 * 현재는 뼈대(stub) 값으로 채워지며 향후 Whisper STT + GPT 분석으로 대체 예정.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiAnalysisResult {

    /** 전반적 적합도 점수 (0.0 ~ 1.0) */
    private Double overallScore;

    /** STT로 추출된 핵심 키워드 목록 */
    private List<String> keywords;

    /** 감정 분석 점수 (0.0 긍정 ~ 1.0 매우 긍정) */
    private Double sentimentScore;

    /** 의사소통 명확성 점수 (0.0 ~ 1.0) */
    private Double communicationScore;

    /** 전문성 점수 (0.0 ~ 1.0) */
    private Double professionalismScore;

    /** 분석 엔진 추천 결과: APPROVED / REVIEW_NEEDED / REJECTED */
    private String recommendation;

    /** 분석 모델 버전 식별자 */
    private String analysisVersion;

    /** 분석 실패 사유 (오류 발생 시에만 설정) */
    private String errorReason;
}
