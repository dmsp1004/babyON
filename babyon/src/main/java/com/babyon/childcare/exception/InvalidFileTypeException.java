package com.babyon.childcare.exception;

/**
 * 잘못된 파일 타입 예외
 */
public class InvalidFileTypeException extends BusinessException {
    public InvalidFileTypeException(String fileName, String expectedType) {
        super("INVALID_FILE_TYPE",
              String.format("%s is not a valid %s file", fileName, expectedType));
    }

    public InvalidFileTypeException(String message) {
        super("INVALID_FILE_TYPE", message);
    }
}
