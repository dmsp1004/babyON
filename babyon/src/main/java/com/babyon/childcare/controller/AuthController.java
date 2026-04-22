package com.babyon.childcare.controller;

import com.babyon.childcare.dto.AuthResponse;
import com.babyon.childcare.dto.LoginRequest;
import com.babyon.childcare.dto.LogoutRequest;
import com.babyon.childcare.dto.RegisterRequest;
import com.babyon.childcare.entity.User;
import com.babyon.childcare.repository.UserRepository;
import com.babyon.childcare.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    @Autowired
    private UserService userService;
    @Autowired
    private UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(userService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        System.out.println("로그인 요청: " + request.getEmail());
        try {
            AuthResponse response = userService.login(request);
            System.out.println("로그인 성공: " + request.getEmail());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            System.out.println("로그인 실패: " + e.getMessage());
            throw e;
        }
    }

    @GetMapping("/validate-token")
    public ResponseEntity<?> validateToken() {

        // SecurityContext에서 현재 인증된 사용자 정보 가져오기
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication != null && authentication.isAuthenticated() &&
                !(authentication instanceof AnonymousAuthenticationToken)) {
            String email = authentication.getName();
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));

            return ResponseEntity.ok(Map.of(
                    "valid", true,
                    "email", email,
                    "userId", user.getId(),
                    "role", user.getUserType().toString()
            ));
        }

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("valid", false));
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> request) {
        String refreshToken = request.get("refreshToken");
        if (!StringUtils.hasText(refreshToken)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "refreshToken 값이 필요합니다"));
        }
        try {
            AuthResponse response = userService.refreshAccessToken(refreshToken);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * 로그아웃
     *
     * JWT가 유효한 상태에서는 소유권 검증 후 Refresh Token을 폐기한다.
     * JWT가 만료된 경우에도 Refresh Token 값 자체를 폐기하는 fallback을 제공한다.
     *
     * logoutAllDevices=true 이면 해당 계정의 모든 Refresh Token을 일괄 폐기한다.
     */
    @PostMapping("/logout")
    public ResponseEntity<?> logout(
            Authentication authentication,
            @RequestBody(required = false) LogoutRequest request) {

        String refreshToken = request != null ? request.getRefreshToken() : null;
        boolean logoutAllDevices = request != null && request.isLogoutAllDevices();

        boolean isIdentified = authentication != null
                && authentication.isAuthenticated()
                && !(authentication instanceof AnonymousAuthenticationToken);

        if (isIdentified) {
            // JWT 유효: 소유권 검증 포함 삭제
            userService.logout(authentication.getName(), refreshToken, logoutAllDevices);
        } else if (StringUtils.hasText(refreshToken)) {
            // JWT 만료/없음: Refresh Token 값만으로 폐기 (UUID 비추측성에 의존)
            userService.revokeRefreshToken(refreshToken);
        }

        return ResponseEntity.ok(Map.of("message", "로그아웃되었습니다"));
    }
}