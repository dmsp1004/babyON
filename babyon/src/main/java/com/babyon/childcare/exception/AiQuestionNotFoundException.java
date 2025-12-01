package com.babyon.childcare.exception;

/**
 * AI 질문을 찾을 수 없을 때 발생하는 예외
 */
public class AiQuestionNotFoundException extends BusinessException {
    public AiQuestionNotFoundException(Long questionId) {
        super("AI_QUESTION_NOT_FOUND", "AI question not found or inactive with ID: " + questionId);
    }

    public AiQuestionNotFoundException(String message) {
        super("AI_QUESTION_NOT_FOUND", message);
    }
}
