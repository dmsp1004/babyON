package com.babyon.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LogoutRequest {

    /** 무효화할 Refresh Token (선택). 미입력 시 해당 토큰만 건너뜀 */
    private String refreshToken;

    /** true이면 해당 계정의 모든 Refresh Token을 일괄 폐기 (모든 기기 로그아웃) */
    private boolean logoutAllDevices;
}
