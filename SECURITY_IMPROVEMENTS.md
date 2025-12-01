# 🔒 보안 취약점 수정 사항

이 문서는 babyON 프로젝트의 보안 취약점 수정 내역을 기록합니다.

---

## 📋 수정된 보안 취약점 목록

### 1. ✅ 민감 정보 환경 변수 분리

#### 문제점
- 데이터베이스 비밀번호가 `application.properties`에 평문으로 저장됨
- JWT Secret Key가 코드에 하드코딩됨
- Git 히스토리에 민감 정보가 노출될 위험

#### 수정 사항
- `.env.example` 파일 생성으로 환경 변수 템플릿 제공
- `application.properties`에서 기본값 제거, 환경 변수만 사용
- `.gitignore`에 `.env` 추가 (이미 설정되어 있음)

#### 수정된 파일
- `babyon/src/main/resources/application.properties`
- `.env.example` (신규 생성)

#### 사용 방법
```bash
# 1. .env.example을 복사하여 .env 파일 생성
cp .env.example .env

# 2. .env 파일에 실제 값 입력
SPRING_DATASOURCE_PASSWORD=your_real_password
JWT_SECRET=your_real_jwt_secret_at_least_256_bits

# 3. 애플리케이션 실행 시 환경 변수 로드
```

---

### 2. ✅ 커스텀 예외 처리 구현

#### 문제점
- 모든 예외를 `RuntimeException`으로 처리
- 클라이언트에게 구체적인 오류 정보 제공 불가
- 스택 트레이스가 노출될 위험

#### 수정 사항
- 비즈니스 예외 기본 클래스 `BusinessException` 구현
- 도메인별 커스텀 예외 클래스 생성:
  - `SitterNotFoundException`: 시터를 찾을 수 없을 때
  - `AiQuestionNotFoundException`: AI 질문을 찾을 수 없을 때
  - `ProfileNotFoundException`: 프로필을 찾을 수 없을 때
  - `InvalidFileException`: 잘못된 파일
  - `FileSizeExceededException`: 파일 크기 초과
  - `InvalidFileTypeException`: 잘못된 파일 타입
  - `VideoDurationExceededException`: 영상 길이 초과
  - `UnauthorizedAccessException`: 권한 없는 접근

#### 생성된 파일
- `exception/BusinessException.java`
- `exception/SitterNotFoundException.java`
- `exception/AiQuestionNotFoundException.java`
- `exception/ProfileNotFoundException.java`
- `exception/InvalidFileException.java`
- `exception/FileSizeExceededException.java`
- `exception/InvalidFileTypeException.java`
- `exception/VideoDurationExceededException.java`
- `exception/UnauthorizedAccessException.java`

---

### 3. ✅ 전역 예외 핸들러 구현

#### 문제점
- 예외 처리가 일관되지 않음
- 클라이언트에게 표준화된 에러 응답 제공 불가

#### 수정 사항
- `@RestControllerAdvice`를 사용한 전역 예외 핸들러 구현
- 표준화된 에러 응답 DTO (`ErrorResponse`) 생성
- HTTP 상태 코드와 에러 코드 매핑
- 로깅을 통한 에러 추적 강화

#### 생성된 파일
- `exception/GlobalExceptionHandler.java`
- `dto/ErrorResponse.java`

#### 에러 응답 예시
```json
{
  "success": false,
  "errorCode": "SITTER_NOT_FOUND",
  "message": "Sitter not found with ID: 123",
  "timestamp": "2025-12-01T10:30:45"
}
```

---

### 4. ✅ 시터 인증/인가 로직 구현

#### 문제점
- 시터 ID를 요청 파라미터로 받아 권한 검증 없이 다른 사용자의 프로필 수정 가능
- Authentication 객체를 사용하지 않음

#### 수정 사항
- `AuthenticationHelper` 유틸리티 클래스 생성
  - Authentication에서 사용자 이메일 추출
  - Authentication에서 사용자 ID 추출
  - 리소스 접근 권한 검증
  - 시터 역할 검증
- `SitterAiProfileController` API 수정:
  - 시터 ID를 파라미터로 받지 않고 Authentication에서 추출
  - 업로드/조회 시 본인 여부 확인
  - `/ai-profile/me` 엔드포인트 추가 (인증된 사용자 전용)
  - `/ai-profile/{sitterId}` 엔드포인트 유지 (공개 프로필 조회용)

#### 수정된 파일
- `util/AuthenticationHelper.java` (신규 생성)
- `controller/SitterAiProfileController.java`

#### API 변경 사항
**이전:**
```http
PUT /api/v1/sitter/ai-profile?sitterId=123
```

**변경 후:**
```http
PUT /api/v1/sitter/ai-profile
Authorization: Bearer {JWT_TOKEN}
# 시터 ID는 토큰에서 자동 추출
```

---

### 5. ✅ CORS 설정 프로덕션 분리

#### 문제점
- 모든 localhost 포트를 허용하는 개발 환경 설정이 하드코딩됨
- 프로덕션 환경에서 보안 위험

#### 수정 사항
- CORS 허용 origins를 환경 변수로 분리
- `application.properties`에 기본값 설정
- `SecurityConfig`에서 환경 변수 읽기

#### 수정된 파일
- `config/SecurityConfig.java`
- `babyon/src/main/resources/application.properties`

#### 사용 방법
```bash
# 개발 환경
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# 프로덕션 환경
ALLOWED_ORIGINS=https://babyon.com,https://www.babyon.com
```

---

## 🚀 적용 방법

### 1. 환경 변수 설정

프로젝트 루트에 `.env` 파일 생성:

```bash
# 데이터베이스 설정
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/babyon_db?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=your_secure_password

# JWT 설정
JWT_SECRET=your-super-secret-jwt-key-minimum-256-bits-for-hs256
JWT_EXPIRATION=86400000

# CORS 설정
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### 2. 애플리케이션 실행

```bash
# Gradle 사용 시 환경 변수 자동 로드
./gradlew bootRun

# 또는 환경 변수 직접 지정
SPRING_DATASOURCE_PASSWORD=mypassword ./gradlew bootRun
```

### 3. 프로덕션 배포

프로덕션 환경에서는 시스템 환경 변수 또는 비밀 관리 서비스 사용:

- **AWS**: AWS Secrets Manager, Parameter Store
- **Azure**: Azure Key Vault
- **GCP**: Secret Manager
- **Kubernetes**: Kubernetes Secrets

---

## 📊 보안 개선 효과

| 항목 | 개선 전 | 개선 후 |
|------|--------|--------|
| **민감 정보 노출** | ⚠️ DB 비밀번호, JWT Secret 노출 | ✅ 환경 변수로 분리 |
| **예외 처리** | ⚠️ RuntimeException만 사용 | ✅ 커스텀 예외 + 전역 핸들러 |
| **권한 검증** | ❌ 인증 없이 타인 프로필 수정 가능 | ✅ Authentication 기반 권한 검증 |
| **CORS 설정** | ⚠️ 모든 localhost 허용 | ✅ 환경별 origins 제한 |
| **에러 로깅** | ⚠️ 일관성 없음 | ✅ 표준화된 로깅 |

---

## 🔜 향후 개선 사항

### 단기 (1-2주)
- [ ] 파일 업로드 검증 강화 (Magic Number 검증)
- [ ] S3 실제 업로드 구현
- [ ] FFmpeg를 사용한 영상 길이 실제 검증
- [ ] Rate Limiting 구현

### 중기 (1개월)
- [ ] OAuth2 토큰 갱신 로직 구현
- [ ] 비밀번호 정책 강화 (길이, 복잡도)
- [ ] 2FA (Two-Factor Authentication) 구현
- [ ] 감사 로그 (Audit Log) 시스템 구축

### 장기 (3개월)
- [ ] JWT를 RS256 (비대칭키)로 마이그레이션
- [ ] API Rate Limiting (Redis 기반)
- [ ] OWASP Dependency Check 통합
- [ ] 보안 헤더 추가 (CSP, HSTS, X-Frame-Options)

---

## 📝 참고 자료

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Spring Security Reference](https://docs.spring.io/spring-security/reference/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [CORS Best Practices](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

---

**작성일**: 2025-12-01
**작성자**: Claude Code
**버전**: 1.0
