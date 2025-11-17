package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterAvailableTimeRequest {
    private String dayOfWeek; // MONDAY, TUESDAY, etc.
    private LocalTime startTime;
    private LocalTime endTime;
    private Boolean isFlexible;
}
