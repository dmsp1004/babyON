package com.babyon.childcare.dto;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterProfileRequest {

    @Size(max = 500, message = "프로필 이미지 URL은 500자 이하이어야 합니다")
    private String profileImageUrl;

    @Size(max = 2000, message = "자기소개는 2000자 이하이어야 합니다")
    private String introduction;

    private List<String> availableServiceTypes; // SHORT_TERM, LONG_TERM, LIVE_IN, PICKUP_DROPOFF

    private List<String> preferredAgeGroups; // INFANT, TODDLER, PRESCHOOL, SCHOOL_AGE

    private List<String> languagesSpoken;

    @Size(max = 100, message = "학력은 100자 이하이어야 합니다")
    private String educationLevel;
}
