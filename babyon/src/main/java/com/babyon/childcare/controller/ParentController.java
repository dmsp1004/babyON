package com.babyon.childcare.controller;

import com.babyon.childcare.dto.ParentProfileResponse;
import com.babyon.childcare.dto.ParentProfileUpdateRequest;
import com.babyon.childcare.service.ParentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

/**
 * 부모 프로필 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/parent")
@RequiredArgsConstructor
@Slf4j
public class ParentController {

    private final ParentService parentService;

    /**
     * 내 부모 프로필 조회
     * @param authentication 인증 정보
     * @return 부모 프로필 정보
     */
    @GetMapping("/profile/me")
    @PreAuthorize("hasRole('PARENT')")
    public ResponseEntity<ParentProfileResponse> getMyProfile(Authentication authentication) {
        Long parentId = Long.parseLong(authentication.getName());
        log.info("부모 프로필 조회 요청: parentId={}", parentId);

        ParentProfileResponse response = parentService.getProfile(parentId);
        return ResponseEntity.ok(response);
    }

    /**
     * 특정 부모 프로필 조회 (공개 - 부모/시터/관리자 모두 접근 가능)
     * @param parentId 부모 ID
     * @return 부모 프로필 정보
     */
    @GetMapping("/profile/{parentId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ParentProfileResponse> getProfile(@PathVariable Long parentId) {
        log.info("부모 프로필 조회 요청: parentId={}", parentId);

        ParentProfileResponse response = parentService.getProfile(parentId);
        return ResponseEntity.ok(response);
    }

    /**
     * 내 부모 프로필 수정
     * @param authentication 인증 정보
     * @param request 프로필 수정 요청
     * @return 수정된 프로필 정보
     */
    @PatchMapping("/profile")
    @PreAuthorize("hasRole('PARENT')")
    public ResponseEntity<ParentProfileResponse> updateMyProfile(
            Authentication authentication,
            @Valid @RequestBody ParentProfileUpdateRequest request) {
        Long parentId = Long.parseLong(authentication.getName());
        log.info("부모 프로필 수정 요청: parentId={}, request={}", parentId, request);

        ParentProfileResponse response = parentService.updateProfile(parentId, request);
        return ResponseEntity.ok(response);
    }

    /**
     * 부모 프로필 존재 여부 확인
     * @param authentication 인증 정보
     * @return 프로필 존재 여부
     */
    @GetMapping("/profile/me/exists")
    @PreAuthorize("hasRole('PARENT')")
    public ResponseEntity<Boolean> profileExists(Authentication authentication) {
        Long parentId = Long.parseLong(authentication.getName());
        log.info("부모 프로필 존재 여부 확인 요청: parentId={}", parentId);

        boolean exists = parentService.exists(parentId);
        return ResponseEntity.ok(exists);
    }
}
