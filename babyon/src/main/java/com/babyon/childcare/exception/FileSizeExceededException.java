package com.babyon.childcare.exception;

/**
 * 파일 크기 초과 예외
 */
public class FileSizeExceededException extends BusinessException {
    public FileSizeExceededException(String fileName, long maxSize) {
        super("FILE_SIZE_EXCEEDED",
              String.format("%s exceeds maximum file size of %d MB", fileName, maxSize / 1024 / 1024));
    }

    public FileSizeExceededException(String message) {
        super("FILE_SIZE_EXCEEDED", message);
    }
}
