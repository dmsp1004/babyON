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
public class SitterCertificationRequest {
    private String certificationName;
    private String issuedBy;
    private LocalDate issueDate;
    private LocalDate expiryDate;
    private String certificateImageUrl;
    private String description;
}
