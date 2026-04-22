package com.babyon.childcare.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

// 구인글 생성/수정 요청 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobPostingRequest {

    @NotBlank(message = "제목은 필수입니다")
    @Size(min = 2, max = 100, message = "제목은 2자 이상 100자 이하이어야 합니다")
    private String title;

    @NotBlank(message = "상세 내용은 필수입니다")
    @Size(min = 10, max = 3000, message = "상세 내용은 10자 이상 3000자 이하이어야 합니다")
    private String description;

    @NotBlank(message = "위치는 필수입니다")
    @Size(max = 255, message = "위치는 255자 이하이어야 합니다")
    private String location;

    @NotNull(message = "시작 날짜는 필수입니다")
    private LocalDateTime startDate;

    @NotNull(message = "종료 날짜는 필수입니다")
    private LocalDateTime endDate;

    @NotNull(message = "급여는 필수입니다")
    @Positive(message = "급여는 0보다 커야 합니다")
    private Double hourlyRate;

    @Pattern(regexp = "^(HOURLY|DAILY|MONTHLY)$", message = "급여 타입은 HOURLY, DAILY, MONTHLY 중 하나여야 합니다")
    private String payType;

    @Min(value = 0, message = "요구 경력 연수는 0 이상이어야 합니다")
    @Max(value = 50, message = "요구 경력 연수는 50 이하이어야 합니다")
    private Integer requiredExperienceYears;

    @NotBlank(message = "구인 유형은 필수입니다")
    @Pattern(regexp = "^(REGULAR_CARE|SCHOOL_ESCORT|ONE_TIME|EMERGENCY)$",
             message = "구인 유형은 REGULAR_CARE, SCHOOL_ESCORT, ONE_TIME, EMERGENCY 중 하나여야 합니다")
    private String jobType;

    @Size(max = 100, message = "아이 나이 정보는 100자 이하이어야 합니다")
    private String ageOfChildren;

    @NotNull(message = "아이 숫자는 필수입니다")
    @Min(value = 1, message = "아이 숫자는 1 이상이어야 합니다")
    @Max(value = 20, message = "아이 숫자는 20 이하이어야 합니다")
    private Integer numberOfChildren;
}
