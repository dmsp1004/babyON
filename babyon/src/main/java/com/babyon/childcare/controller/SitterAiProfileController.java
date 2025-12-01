package com.babyon.childcare.controller;

import com.babyon.childcare.dto.AiProfileResponse;
import com.babyon.childcare.dto.AiProfileUploadRequest;
import com.babyon.childcare.dto.AiQuestionResponse;
import com.babyon.childcare.service.SitterAiVideoProfileService;
import com.babyon.childcare.util.AuthenticationHelper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * 시터 AI 화상 이력서 Controller
 * AI 질문 랜덤 선택 및 화상 이력서 업로드 API
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/sitter")
@RequiredArgsConstructor
@Validated
@Tag(name = "Sitter AI Video Profile", description = "시터 AI 화상 이력서 관리 API")
public class SitterAiProfileController {

    private final SitterAiVideoProfileService aiVideoProfileService;
    private final AuthenticationHelper authenticationHelper;

    /**
     * 랜덤 AI 질문 조회
     * 시터가 녹화 전에 랜덤 질문을 가져옵니다.
     *
     * @return AiQuestionResponse - 질문 ID, 질문 내용, 시간 제한 등
     */
    @GetMapping("/ai-question/random")
    @Operation(summary = "랜덤 AI 질문 조회", description = "시터 화상 이력서용 랜덤 AI 질문을 조회합니다")
    public ResponseEntity<AiQuestionResponse> getRandomQuestion() {
        log.info("Fetching random AI question");

        AiQuestionResponse response = aiVideoProfileService.getRandomQuestion();

        return ResponseEntity.ok(response);
    }

    /**
     * AI 화상 이력서 업로드/업데이트
     * 시터가 자유 소개 영상과 AI 질문 답변 영상을 업로드합니다.
     *
     * HTTP Method: PUT (Create or Update)
     * Endpoint: /api/v1/sitter/ai-profile
     *
     * Request Parameters:
     * - introVideo (MultipartFile): 자유 소개 영상 파일 (최대 120초, 100MB)
     * - answerVideo (MultipartFile): AI 질문 답변 영상 파일 (최대 120초, 100MB)
     * - aiQuestionId (Long): 답변한 AI 질문 ID
     * - status (String, Optional): 프로필 상태 (PENDING, ACTIVE, INACTIVE, REVIEWING)
     *
     * Validation:
     * - 각 영상 파일의 길이는 최대 120초로 제한됩니다 (Service 레이어에서 검증)
     * - 파일 크기는 최대 100MB로 제한됩니다
     * - 비디오 형식만 허용됩니다 (MIME type: video/*)
     *
     * Security:
     * - Authentication에서 시터 ID를 추출하여 본인의 프로필만 수정 가능
     * - SITTER 역할만 접근 가능
     *
     * TODO: 실제 S3 업로드 구현 필요 (현재는 Mock URL 반환)
     * TODO: FFmpeg를 사용한 실제 영상 길이 검증 구현 필요
     *
     * @param introVideo 자유 소개 영상 파일
     * @param answerVideo AI 질문 답변 영상 파일
     * @param aiQuestionId 답변한 AI 질문 ID
     * @param status 프로필 상태 (선택 사항)
     * @param authentication 인증 정보
     * @return AiProfileResponse - 업로드된 프로필 정보
     */
    @PutMapping(value = "/ai-profile", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "AI 화상 이력서 업로드", description = "시터의 AI 화상 이력서(자유 소개 + AI 질문 답변)를 업로드합니다")
    public ResponseEntity<AiProfileResponse> uploadOrUpdateProfile(
            @RequestParam("introVideo") @NotNull MultipartFile introVideo,
            @RequestParam("answerVideo") @NotNull MultipartFile answerVideo,
            @RequestParam("aiQuestionId") @Positive Long aiQuestionId,
            @RequestParam(value = "status", required = false) String status,
            Authentication authentication) {

        // 1. 시터 역할 검증
        authenticationHelper.validateSitterRole(authentication);

        // 2. Authentication에서 시터 ID 추출
        Long sitterId = authenticationHelper.getUserId(authentication);
        log.info("Uploading AI video profile for authenticated sitter: {}", sitterId);

        // 3. Request DTO 구성
        AiProfileUploadRequest request = AiProfileUploadRequest.builder()
                .introVideo(introVideo)
                .answerVideo(answerVideo)
                .aiQuestionId(aiQuestionId)
                .status(status)
                .build();

        // 4. Service 호출 (파일 업로드 및 DB 저장)
        AiProfileResponse response = aiVideoProfileService.uploadOrUpdateProfile(sitterId, request);

        log.info("AI video profile uploaded successfully for sitter: {}", sitterId);

        return ResponseEntity.ok(response);
    }

    /**
     * AI 화상 이력서 조회 (내 프로필)
     * 인증된 시터가 본인의 AI 화상 이력서를 조회합니다.
     *
     * @param authentication 인증 정보
     * @return AiProfileResponse - 프로필 정보
     */
    @GetMapping("/ai-profile/me")
    @Operation(summary = "내 AI 화상 이력서 조회", description = "인증된 시터의 AI 화상 이력서를 조회합니다")
    public ResponseEntity<AiProfileResponse> getMyProfile(Authentication authentication) {
        // 시터 역할 검증
        authenticationHelper.validateSitterRole(authentication);

        // Authentication에서 시터 ID 추출
        Long sitterId = authenticationHelper.getUserId(authentication);
        log.info("Fetching AI video profile for authenticated sitter: {}", sitterId);

        AiProfileResponse response = aiVideoProfileService.getProfile(sitterId);

        return ResponseEntity.ok(response);
    }

    /**
     * AI 화상 이력서 조회 (공개)
     * 특정 시터의 AI 화상 이력서를 조회합니다 (공개 프로필).
     * 부모가 시터의 프로필을 볼 때 사용합니다.
     *
     * @param sitterId 시터 ID
     * @return AiProfileResponse - 프로필 정보
     */
    @GetMapping("/ai-profile/{sitterId}")
    @Operation(summary = "AI 화상 이력서 조회", description = "특정 시터의 AI 화상 이력서를 조회합니다 (공개 프로필)")
    public ResponseEntity<AiProfileResponse> getProfile(@PathVariable @Positive Long sitterId) {
        log.info("Fetching AI video profile for sitter: {}", sitterId);

        AiProfileResponse response = aiVideoProfileService.getProfile(sitterId);

        return ResponseEntity.ok(response);
    }

    /**
     * AI 화상 이력서 존재 여부 확인 (내 프로필)
     * 인증된 시터가 본인의 AI 화상 이력서 등록 여부를 확인합니다.
     *
     * @param authentication 인증 정보
     * @return Boolean - 존재 여부
     */
    @GetMapping("/ai-profile/me/exists")
    @Operation(summary = "내 AI 화상 이력서 존재 여부", description = "인증된 시터의 AI 화상 이력서 존재 여부를 확인합니다")
    public ResponseEntity<Boolean> hasMyProfile(Authentication authentication) {
        // 시터 역할 검증
        authenticationHelper.validateSitterRole(authentication);

        // Authentication에서 시터 ID 추출
        Long sitterId = authenticationHelper.getUserId(authentication);
        log.info("Checking AI video profile existence for authenticated sitter: {}", sitterId);

        boolean exists = aiVideoProfileService.hasProfile(sitterId);

        return ResponseEntity.ok(exists);
    }
}
