package com.babyon.childcare.dto;

import jakarta.validation.constraints.*;
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

    @NotBlank(message = "회사/기관명은 필수입니다")
    @Size(max = 200, message = "회사/기관명은 200자 이하이어야 합니다")
    private String companyName;

    @NotBlank(message = "직책/역할은 필수입니다")
    @Size(max = 100, message = "직책/역할은 100자 이하이어야 합니다")
    private String position;

    @NotNull(message = "시작일은 필수입니다")
    @PastOrPresent(message = "시작일은 현재 이전이어야 합니다")
    private LocalDate startDate;

    private LocalDate endDate;

    private Boolean isCurrent;

    @Size(max = 1000, message = "설명은 1000자 이하이어야 합니다")
    private String description;

    @Size(max = 100, message = "담당 아이 나이대는 100자 이하이어야 합니다")
    private String childrenAgeGroup;

    @Min(value = 1, message = "담당 아이 수는 1 이상이어야 합니다")
    @Max(value = 50, message = "담당 아이 수는 50 이하이어야 합니다")
    private Integer numberOfChildren;
}
