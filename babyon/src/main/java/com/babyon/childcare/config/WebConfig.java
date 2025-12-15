package com.babyon.childcare.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * CORS(Cross-Origin Resource Sharing) 설정
 * 보안을 위해 특정 도메인만 허용하도록 구성
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.cors.allowed-origins:http://localhost:*,http://127.0.0.1:*}")
    private String allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                // 보안 강화: 특정 출처만 허용 (application.properties에서 설정)
                // 개발: http://localhost:*, http://127.0.0.1:*
                // 프로덕션: https://yourdomain.com, https://app.yourdomain.com
                .allowedOriginPatterns(allowedOrigins.split(","))
                .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
                // 필요한 헤더만 명시적으로 허용
                .allowedHeaders("Authorization", "Content-Type", "Accept", "X-Requested-With")
                .exposedHeaders("Authorization")
                .allowCredentials(true) // 쿠키/인증 정보 허용
                .maxAge(3600); // preflight 요청 결과를 1시간 동안 캐시
    }
}