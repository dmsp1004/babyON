package com.babyon.childcare.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OAuthRegisterRequest {

    @NotBlank(message = "이메일은 필수입니다")
    @Email(message = "올바른 이메일 형식이 아닙니다")
    private String email;

    @Pattern(regexp = "^01[0-9]-\\d{3,4}-\\d{4}$", message = "전화번호 형식이 올바르지 않습니다. (예: 010-1234-5678)")
    private String phoneNumber;

    @NotBlank(message = "OAuth 제공자는 필수입니다")
    @Pattern(regexp = "^(google|kakao|naver)$", message = "지원하지 않는 OAuth 제공자입니다")
    private String provider;

    @NotBlank(message = "제공자 ID는 필수입니다")
    private String providerId;

    @NotBlank(message = "사용자 유형은 필수입니다")
    @Pattern(regexp = "^(PARENT|SITTER)$", message = "사용자 유형은 PARENT, SITTER 중 하나여야 합니다")
    private String userType;

    // 부모(Parent)에 필요한 추가 정보
    private Integer numberOfChildren;

    @Size(max = 255, message = "주소는 255자 이하이어야 합니다")
    private String address;

    @Size(max = 1000, message = "추가 정보는 1000자 이하이어야 합니다")
    private String additionalInfo;

    // 시터(Sitter)에 필요한 추가 정보
    private String sitterType;  // "SCHOOL_ESCORT", "REGULAR_SITTER"
    private Integer experienceYears;
    private Double hourlyRate;

    @Size(max = 2000, message = "자기소개는 2000자 이하이어야 합니다")
    private String bio;
}