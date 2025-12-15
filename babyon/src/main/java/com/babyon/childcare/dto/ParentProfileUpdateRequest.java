package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParentProfileUpdateRequest {

    @Min(value = 0, message = "자녀 수는 0 이상이어야 합니다.")
    private Integer numberOfChildren;

    @Size(max = 255, message = "주소는 255자 이하이어야 합니다.")
    private String address;

    @Size(max = 1000, message = "추가 정보는 1000자 이하이어야 합니다.")
    private String additionalInfo;

    @Pattern(regexp = "^01[0-9]-\\d{3,4}-\\d{4}$", message = "전화번호 형식이 올바르지 않습니다. (예: 010-1234-5678)")
    private String phoneNumber;
}
