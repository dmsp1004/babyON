package com.babyon.childcare.dto;

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
    private String profileImageUrl;
    private String introduction;
    private List<String> availableServiceTypes; // SHORT_TERM, LONG_TERM, LIVE_IN, PICKUP_DROPOFF
    private List<String> preferredAgeGroups; // INFANT, TODDLER, PRESCHOOL, SCHOOL_AGE
    private List<String> languagesSpoken;
    private String educationLevel;
}
