package com.babyon.childcare.exception;

/**
 * 권한 없는 접근 예외
 */
public class UnauthorizedAccessException extends BusinessException {
    public UnauthorizedAccessException() {
        super("UNAUTHORIZED_ACCESS", "You do not have permission to access this resource");
    }

    public UnauthorizedAccessException(String message) {
        super("UNAUTHORIZED_ACCESS", message);
    }

    public UnauthorizedAccessException(Long userId, Long resourceId) {
        super("UNAUTHORIZED_ACCESS",
              String.format("User %d does not have permission to access resource %d", userId, resourceId));
    }
}
