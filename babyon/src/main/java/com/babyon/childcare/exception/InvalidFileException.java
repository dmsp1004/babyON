package com.babyon.childcare.exception;

/**
 * 파일 업로드 관련 예외
 */
public class InvalidFileException extends BusinessException {
    public InvalidFileException(String message) {
        super("INVALID_FILE", message);
    }

    public InvalidFileException(String message, Throwable cause) {
        super("INVALID_FILE", message, cause);
    }
}
