package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterVideoResumeResponse {
    private Long id;
    private Long sitterId;
    private String videoUrl;
    private String thumbnailUrl;
    private String title;
    private Integer durationSeconds;
    private BigDecimal fileSizeMb;
    private String aiAnalysisResult;
    private LocalDateTime aiAnalyzedAt;
    private Boolean isPrimary;
    private Integer viewCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
