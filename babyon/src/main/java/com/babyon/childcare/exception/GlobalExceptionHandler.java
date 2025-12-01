package com.babyon.childcare.exception;

import com.babyon.childcare.dto.ErrorResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.nio.file.AccessDeniedException;
import java.util.HashMap;
import java.util.Map;

/**
 * 전역 예외 처리 핸들러
 * 모든 컨트롤러에서 발생하는 예외를 일관되게 처리합니다.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Sitter를 찾을 수 없을 때
     */
    @ExceptionHandler(SitterNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleSitterNotFound(SitterNotFoundException e) {
        log.error("Sitter not found: {}", e.getMessage());
        ErrorResponse response = ErrorResponse.of(e.getErrorCode(), e.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    /**
     * AI 질문을 찾을 수 없을 때
     */
    @ExceptionHandler(AiQuestionNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleAiQuestionNotFound(AiQuestionNotFoundException e) {
        log.error("AI question not found: {}", e.getMessage());
        ErrorResponse response = ErrorResponse.of(e.getErrorCode(), e.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    /**
     * 프로필을 찾을 수 없을 때
     */
    @ExceptionHandler(ProfileNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleProfileNotFound(ProfileNotFoundException e) {
        log.error("Profile not found: {}", e.getMessage());
        ErrorResponse response = ErrorResponse.of(e.getErrorCode(), e.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    /**
     * 권한 없는 접근
     */
    @ExceptionHandler({UnauthorizedAccessException.class, AccessDeniedException.class})
    public ResponseEntity<ErrorResponse> handleUnauthorizedAccess(Exception e) {
        log.error("Unauthorized access: {}", e.getMessage());
        String errorCode = e instanceof UnauthorizedAccessException
                ? ((UnauthorizedAccessException) e).getErrorCode()
                : "ACCESS_DENIED";
        ErrorResponse response = ErrorResponse.of(errorCode, e.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
    }

    /**
     * 파일 크기 초과
     */
    @ExceptionHandler({FileSizeExceededException.class, MaxUploadSizeExceededException.class})
    public ResponseEntity<ErrorResponse> handleFileSizeExceeded(Exception e) {
        log.error("File size exceeded: {}", e.getMessage());
        String errorCode = e instanceof FileSizeExceededException
                ? ((FileSizeExceededException) e).getErrorCode()
                : "FILE_SIZE_EXCEEDED";
        String message = e instanceof MaxUploadSizeExceededException
                ? "파일 크기가 허용된 최대 크기를 초과했습니다"
                : e.getMessage();
        ErrorResponse response = ErrorResponse.of(errorCode, message);
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).body(response);
    }

    /**
     * 잘못된 파일 타입
     */
    @ExceptionHandler(InvalidFileTypeException.class)
    public ResponseEntity<ErrorResponse> handleInvalidFileType(InvalidFileTypeException e) {
        log.error("Invalid file type: {}", e.getMessage());
        ErrorResponse response = ErrorResponse.of(e.getErrorCode(), e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * 잘못된 파일
     */
    @ExceptionHandler(InvalidFileException.class)
    public ResponseEntity<ErrorResponse> handleInvalidFile(InvalidFileException e) {
        log.error("Invalid file: {}", e.getMessage());
        ErrorResponse response = ErrorResponse.of(e.getErrorCode(), e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * 영상 길이 초과
     */
    @ExceptionHandler(VideoDurationExceededException.class)
    public ResponseEntity<ErrorResponse> handleVideoDurationExceeded(VideoDurationExceededException e) {
        log.error("Video duration exceeded: {}", e.getMessage());
        ErrorResponse response = ErrorResponse.of(e.getErrorCode(), e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * Bean Validation 실패
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(MethodArgumentNotValidException e) {
        Map<String, String> errors = new HashMap<>();
        e.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        log.error("Validation failed: {}", errors);
        ErrorResponse response = ErrorResponse.of("VALIDATION_FAILED", "입력값 검증에 실패했습니다: " + errors.toString());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * 비즈니스 예외 (기타)
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException e) {
        log.error("Business exception: {} - {}", e.getErrorCode(), e.getMessage());
        ErrorResponse response = ErrorResponse.of(e.getErrorCode(), e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * 일반 예외 (예상하지 못한 에러)
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneralException(Exception e) {
        log.error("Unexpected error occurred", e);
        ErrorResponse response = ErrorResponse.of(
                "INTERNAL_SERVER_ERROR",
                "서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}
