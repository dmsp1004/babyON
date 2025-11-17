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
public class SitterCertificationResponse {
    private Long id;
    private Long sitterId;
    private String certificationName;
    private String issuedBy;
    private LocalDate issueDate;
    private LocalDate expiryDate;
    private String certificateImageUrl;
    private String description;
    private Boolean isVerified;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
