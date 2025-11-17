package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterProfileResponse {
    private Long id;
    private Long sitterId;
    private String sitterEmail;
    private String profileImageUrl;
    private String introduction;
    private List<String> availableServiceTypes;
    private List<String> preferredAgeGroups;
    private List<String> languagesSpoken;
    private String educationLevel;
    private BigDecimal rating;
    private Integer totalReviews;
    private Boolean profileCompleted;
    private Boolean isActive;

    // From Sitter entity
    private String sitterType;
    private Integer experienceYears;
    private Double hourlyRate;
    private String bio;
    private Boolean isVerified;

    // Related data
    private List<SitterCertificationResponse> certifications;
    private List<SitterExperienceResponse> experiences;
    private List<SitterAvailableTimeResponse> availableTimes;
    private List<SitterServiceAreaResponse> serviceAreas;
    private SitterVideoResumeResponse primaryVideoResume;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
