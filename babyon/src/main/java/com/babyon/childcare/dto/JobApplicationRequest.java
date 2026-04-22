package com.babyon.childcare.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

// 지원서 생성/수정 요청 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobApplicationRequest {

    @NotNull(message = "구인글 ID는 필수입니다")
    @Positive(message = "구인글 ID는 양수여야 합니다")
    private Long jobPostingId;

    @Size(max = 2000, message = "자기소개는 2000자 이하이어야 합니다")
    private String coverLetter;

    @Positive(message = "제안 시급은 0보다 커야 합니다")
    private Double proposedHourlyRate;
}