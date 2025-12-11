package com.babyon.childcare.dto;

import com.babyon.childcare.entity.Parent;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParentProfileResponse {

    private Long id;
    private String email;
    private String phoneNumber;
    private Integer numberOfChildren;
    private String address;
    private String additionalInfo;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    /**
     * Parent 엔티티로부터 DTO 생성
     */
    public static ParentProfileResponse from(Parent parent) {
        return ParentProfileResponse.builder()
                .id(parent.getId())
                .email(parent.getEmail())
                .phoneNumber(parent.getPhoneNumber())
                .numberOfChildren(parent.getNumberOfChildren())
                .address(parent.getAddress())
                .additionalInfo(parent.getAdditionalInfo())
                .createdAt(parent.getCreatedAt())
                .updatedAt(parent.getUpdatedAt())
                .build();
    }
}
