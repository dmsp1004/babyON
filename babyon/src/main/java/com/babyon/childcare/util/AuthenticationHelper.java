package com.babyon.childcare.util;

import com.babyon.childcare.entity.User;
import com.babyon.childcare.exception.UnauthorizedAccessException;
import com.babyon.childcare.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

/**
 * 인증 관련 헬퍼 유틸리티
 * Authentication 객체에서 사용자 정보 추출 및 권한 검증
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuthenticationHelper {

    private final UserRepository userRepository;

    /**
     * Authentication에서 사용자 이메일 추출
     */
    public String getUserEmail(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new UnauthorizedAccessException("User is not authenticated");
        }
        return authentication.getName();
    }

    /**
     * Authentication에서 사용자 ID 추출
     */
    public Long getUserId(Authentication authentication) {
        String email = getUserEmail(authentication);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedAccessException("User not found: " + email));
        return user.getId();
    }

    /**
     * 인증된 사용자가 특정 리소스에 접근 권한이 있는지 검증
     * @param authentication 인증 정보
     * @param resourceOwnerId 리소스 소유자 ID
     * @throws UnauthorizedAccessException 권한이 없을 경우
     */
    public void validateResourceAccess(Authentication authentication, Long resourceOwnerId) {
        Long userId = getUserId(authentication);
        if (!userId.equals(resourceOwnerId)) {
            log.warn("Unauthorized access attempt: user {} tried to access resource owned by {}",
                    userId, resourceOwnerId);
            throw new UnauthorizedAccessException(userId, resourceOwnerId);
        }
    }

    /**
     * 인증된 사용자가 SITTER 역할인지 확인
     */
    public void validateSitterRole(Authentication authentication) {
        String email = getUserEmail(authentication);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedAccessException("User not found: " + email));

        if (!"SITTER".equals(user.getUserType())) {
            log.warn("User {} is not a sitter (role: {})", email, user.getUserType());
            throw new UnauthorizedAccessException("Only sitters can access this resource");
        }
    }
}
