package com.babyon.childcare.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterServiceAreaRequest {

    @NotBlank(message = "시/도는 필수입니다")
    @Size(max = 50, message = "시/도는 50자 이하이어야 합니다")
    private String city;

    @NotBlank(message = "구/군은 필수입니다")
    @Size(max = 50, message = "구/군은 50자 이하이어야 합니다")
    private String district;

    @Size(max = 100, message = "상세 지역은 100자 이하이어야 합니다")
    private String detailedArea;

    @Min(value = 0, message = "이동 거리는 0 이상이어야 합니다")
    @Max(value = 200, message = "이동 거리는 200km 이하이어야 합니다")
    private Integer travelDistanceKm;

    private Boolean isPrimary;
}
