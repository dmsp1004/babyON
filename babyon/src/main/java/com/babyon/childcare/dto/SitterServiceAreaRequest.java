package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SitterServiceAreaRequest {
    private String city;
    private String district;
    private String detailedArea;
    private Integer travelDistanceKm;
    private Boolean isPrimary;
}
