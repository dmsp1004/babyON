package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterSearchRequest {
    private String city;
    private String district;
    private String serviceType; // SHORT_TERM, LONG_TERM, LIVE_IN, PICKUP_DROPOFF
    private String ageGroup; // INFANT, TODDLER, PRESCHOOL, SCHOOL_AGE
    private Double minRating;
    private Integer minExperienceYears;
    private Double maxHourlyRate;
    private String dayOfWeek;
    private String sortBy; // rating, experience, hourlyRate, createdAt
    private String sortDirection; // asc, desc
    private Integer page;
    private Integer size;
}
