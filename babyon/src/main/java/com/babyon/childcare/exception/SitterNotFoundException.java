package com.babyon.childcare.exception;

/**
 * 시터를 찾을 수 없을 때 발생하는 예외
 */
public class SitterNotFoundException extends BusinessException {
    public SitterNotFoundException(Long sitterId) {
        super("SITTER_NOT_FOUND", "Sitter not found with ID: " + sitterId);
    }

    public SitterNotFoundException(String email) {
        super("SITTER_NOT_FOUND", "Sitter not found with email: " + email);
    }
}
