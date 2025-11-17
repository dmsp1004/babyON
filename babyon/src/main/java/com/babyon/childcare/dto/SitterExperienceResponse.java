package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterExperienceResponse {
    private Long id;
    private Long sitterId;
    private String companyName;
    private String position;
    private LocalDate startDate;
    private LocalDate endDate;
    private Boolean isCurrent;
    private String description;
    private String childrenAgeGroup;
    private Integer numberOfChildren;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
