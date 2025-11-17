package com.babyon.childcare.controller;

import com.babyon.childcare.dto.*;
import com.babyon.childcare.service.SitterProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/sitter-profiles")
@RequiredArgsConstructor
@Tag(name = "Sitter Profile", description = "시터 프로필 관리 API")
public class SitterProfileController {

    private final SitterProfileService sitterProfileService;

    @GetMapping("/{sitterId}")
    @Operation(summary = "시터 프로필 조회", description = "특정 시터의 프로필을 조회합니다")
    public ResponseEntity<SitterProfileResponse> getProfile(@PathVariable Long sitterId) {
        SitterProfileResponse response = sitterProfileService.getOrCreateProfile(sitterId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{sitterId}")
    @Operation(summary = "시터 프로필 수정", description = "시터 프로필을 수정합니다")
    public ResponseEntity<SitterProfileResponse> updateProfile(
            @PathVariable Long sitterId,
            @RequestBody SitterProfileRequest request,
            Authentication authentication) {
        // TODO: Verify that the authenticated user is the sitter
        SitterProfileResponse response = sitterProfileService.updateProfile(sitterId, request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/search")
    @Operation(summary = "시터 검색", description = "조건에 맞는 시터를 검색합니다")
    public ResponseEntity<Page<SitterProfileResponse>> searchProfiles(
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String district,
            @RequestParam(required = false) String serviceType,
            @RequestParam(required = false) String ageGroup,
            @RequestParam(required = false) Double minRating,
            @RequestParam(required = false) Integer minExperienceYears,
            @RequestParam(required = false) Double maxHourlyRate,
            @RequestParam(required = false) String dayOfWeek,
            @RequestParam(required = false, defaultValue = "rating") String sortBy,
            @RequestParam(required = false, defaultValue = "desc") String sortDirection,
            @RequestParam(required = false, defaultValue = "0") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size) {

        SitterSearchRequest searchRequest = SitterSearchRequest.builder()
                .city(city)
                .district(district)
                .serviceType(serviceType)
                .ageGroup(ageGroup)
                .minRating(minRating)
                .minExperienceYears(minExperienceYears)
                .maxHourlyRate(maxHourlyRate)
                .dayOfWeek(dayOfWeek)
                .sortBy(sortBy)
                .sortDirection(sortDirection)
                .page(page)
                .size(size)
                .build();

        Page<SitterProfileResponse> response = sitterProfileService.searchProfiles(searchRequest);
        return ResponseEntity.ok(response);
    }

    // Certification endpoints

    @PostMapping("/{sitterId}/certifications")
    @Operation(summary = "자격증 추가", description = "시터의 자격증을 추가합니다")
    public ResponseEntity<SitterCertificationResponse> addCertification(
            @PathVariable Long sitterId,
            @RequestBody SitterCertificationRequest request,
            Authentication authentication) {
        SitterCertificationResponse response = sitterProfileService.addCertification(sitterId, request);
        return ResponseEntity.ok(response);
    }

    // Experience endpoints

    @PostMapping("/{sitterId}/experiences")
    @Operation(summary = "경력 추가", description = "시터의 경력을 추가합니다")
    public ResponseEntity<SitterExperienceResponse> addExperience(
            @PathVariable Long sitterId,
            @RequestBody SitterExperienceRequest request,
            Authentication authentication) {
        SitterExperienceResponse response = sitterProfileService.addExperience(sitterId, request);
        return ResponseEntity.ok(response);
    }

    // Available time endpoints

    @PostMapping("/{sitterId}/available-times")
    @Operation(summary = "가능 시간 추가", description = "시터의 가능한 시간대를 추가합니다")
    public ResponseEntity<SitterAvailableTimeResponse> addAvailableTime(
            @PathVariable Long sitterId,
            @RequestBody SitterAvailableTimeRequest request,
            Authentication authentication) {
        SitterAvailableTimeResponse response = sitterProfileService.addAvailableTime(sitterId, request);
        return ResponseEntity.ok(response);
    }

    // Service area endpoints

    @PostMapping("/{sitterId}/service-areas")
    @Operation(summary = "서비스 지역 추가", description = "시터의 서비스 가능 지역을 추가합니다")
    public ResponseEntity<SitterServiceAreaResponse> addServiceArea(
            @PathVariable Long sitterId,
            @RequestBody SitterServiceAreaRequest request,
            Authentication authentication) {
        SitterServiceAreaResponse response = sitterProfileService.addServiceArea(sitterId, request);
        return ResponseEntity.ok(response);
    }
}
