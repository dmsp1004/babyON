package com.babyon.childcare.exception;

/**
 * 프로필을 찾을 수 없을 때 발생하는 예외
 */
public class ProfileNotFoundException extends BusinessException {
    public ProfileNotFoundException(Long sitterId) {
        super("PROFILE_NOT_FOUND", "AI video profile not found for sitter: " + sitterId);
    }

    public ProfileNotFoundException(String message) {
        super("PROFILE_NOT_FOUND", message);
    }
}
