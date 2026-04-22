package com.babyon.childcare.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
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

    @NotBlank(message = "요일은 필수입니다")
    @Pattern(regexp = "^(MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY)$",
             message = "요일 형식이 올바르지 않습니다")
    private String dayOfWeek;

    @NotNull(message = "시작 시간은 필수입니다")
    private LocalTime startTime;

    @NotNull(message = "종료 시간은 필수입니다")
    private LocalTime endTime;

    private Boolean isFlexible;
}
