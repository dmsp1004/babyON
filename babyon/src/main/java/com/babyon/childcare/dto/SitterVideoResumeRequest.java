package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterVideoResumeRequest {
    private String videoUrl;
    private String thumbnailUrl;
    private String title;
    private Integer durationSeconds;
    private BigDecimal fileSizeMb;
    private Boolean isPrimary;
}
