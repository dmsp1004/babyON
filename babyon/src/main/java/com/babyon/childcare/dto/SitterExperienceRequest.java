package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterExperienceRequest {
    private String companyName;
    private String position;
    private LocalDate startDate;
    private LocalDate endDate;
    private Boolean isCurrent;
    private String description;
    private String childrenAgeGroup;
    private Integer numberOfChildren;
}
