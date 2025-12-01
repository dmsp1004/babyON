package com.babyon.childcare.exception;

/**
 * 영상 길이 초과 예외
 */
public class VideoDurationExceededException extends BusinessException {
    public VideoDurationExceededException(String fileName, int maxDuration, int actualDuration) {
        super("VIDEO_DURATION_EXCEEDED",
              String.format("%s exceeds maximum duration of %d seconds (actual: %d seconds)",
                      fileName, maxDuration, actualDuration));
    }

    public VideoDurationExceededException(String message) {
        super("VIDEO_DURATION_EXCEEDED", message);
    }
}
