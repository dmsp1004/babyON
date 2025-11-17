package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterAvailableTimeResponse {
    private Long id;
    private Long sitterId;
    private String dayOfWeek;
    private LocalTime startTime;
    private LocalTime endTime;
    private Boolean isFlexible;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
