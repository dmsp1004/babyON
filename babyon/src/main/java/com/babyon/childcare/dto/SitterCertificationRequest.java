package com.babyon.childcare.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;
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

    @NotBlank(message = "자격증 이름은 필수입니다")
    @Size(max = 200, message = "자격증 이름은 200자 이하이어야 합니다")
    private String certificationName;

    @NotBlank(message = "발급 기관은 필수입니다")
    @Size(max = 200, message = "발급 기관은 200자 이하이어야 합니다")
    private String issuedBy;

    @NotNull(message = "발급일은 필수입니다")
    @PastOrPresent(message = "발급일은 현재 이전이어야 합니다")
    private LocalDate issueDate;

    private LocalDate expiryDate;

    @Size(max = 500, message = "자격증 이미지 URL은 500자 이하이어야 합니다")
    private String certificateImageUrl;

    @Size(max = 500, message = "설명은 500자 이하이어야 합니다")
    private String description;
}
