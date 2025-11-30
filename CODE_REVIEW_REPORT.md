# AI 화상 이력서 시스템 코드 리뷰 보고서

## 📋 개요
생성된 AI 화상 이력서 시스템 코드의 전체적인 검토 결과를 정리합니다.

---

## 🔴 Critical Issues (즉시 수정 필요)

### 1. **@Modifying 어노테이션 누락**
**파일:** `SitterAiVideoProfileRepository.java:36`

**문제:**
```java
@Query("UPDATE SitterAiVideoProfile sap SET sap.viewCount = sap.viewCount + 1 WHERE sap.sitterId = :sitterId")
void incrementViewCount(@Param("sitterId") Long sitterId);
```

UPDATE/DELETE 쿼리에는 `@Modifying` 어노테이션이 필수입니다.

**해결방법:**
```java
@Modifying
@Transactional
@Query("UPDATE SitterAiVideoProfile sap SET sap.viewCount = sap.viewCount + 1 WHERE sap.sitterId = :sitterId")
void incrementViewCount(@Param("sitterId") Long sitterId);
```

**영향:** 런타임 시 `InvalidDataAccessApiUsageException` 발생

---

### 2. **Enum 타입 불일치**
**파일:** `AiQuestion.java:31`

**문제:**
```java
@Column(name = "question_category", length = 50)
private String questionCategory; // EXPERIENCE, PERSONALITY, SITUATION, MOTIVATION, etc.

// 하지만 아래에 QuestionCategory Enum이 정의되어 있음
public enum QuestionCategory {
    EXPERIENCE, PERSONALITY, SITUATION, MOTIVATION, CHILDCARE
}
```

**해결방법:**
```java
@Column(name = "question_category", length = 50)
@Enumerated(EnumType.STRING)
private QuestionCategory questionCategory;
```

**영향:** 타입 안정성 부족, 잘못된 카테고리 값 입력 가능

---

## 🟡 Major Issues (개선 권장)

### 3. **순환 참조 가능성**
**파일:** `SitterAiVideoProfile.java:18`

**문제:**
```java
@Data  // toString(), equals(), hashCode() 자동 생성
public class SitterAiVideoProfile {
    @OneToOne(fetch = FetchType.LAZY)
    private Sitter sitter;
}
```

`@Data`를 사용하면 관계 매핑된 엔티티에서 순환 참조 발생 가능.

**해결방법:**
```java
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"sitter", "aiQuestion"})  // 순환 참조 방지
@EqualsAndHashCode(exclude = {"sitter", "aiQuestion"})
public class SitterAiVideoProfile {
    // ...
}
```

**영향:** StackOverflowError, JSON 직렬화 시 무한 루프

---

### 4. **Generic한 예외 처리**
**파일:** `SitterAiVideoProfileService.java` 전체

**문제:**
```java
throw new RuntimeException("Sitter not found with ID: " + sitterId);
throw new RuntimeException("AI question not found or inactive: " + request.getAiQuestionId());
```

**해결방법:**
커스텀 예외 클래스 생성:
```java
// 예시
public class SitterNotFoundException extends RuntimeException {
    public SitterNotFoundException(Long sitterId) {
        super("Sitter not found with ID: " + sitterId);
    }
}

public class AiQuestionNotFoundException extends RuntimeException {
    public AiQuestionNotFoundException(Long questionId) {
        super("AI question not found or inactive: " + questionId);
    }
}
```

**영향:** 예외 처리 세분화 부족, 클라이언트에서 적절한 에러 응답 어려움

---

### 5. **DTO 검증 어노테이션 부재**
**파일:** `AiProfileUploadRequest.java`

**문제:**
```java
public class AiProfileUploadRequest {
    private MultipartFile introVideo;
    private MultipartFile answerVideo;
    private Long aiQuestionId;
    private String status;
}
```

입력 검증이 없음.

**해결방법:**
```java
public class AiProfileUploadRequest {
    @NotNull(message = "Intro video is required")
    private MultipartFile introVideo;

    @NotNull(message = "Answer video is required")
    private MultipartFile answerVideo;

    @NotNull(message = "AI question ID is required")
    @Positive(message = "AI question ID must be positive")
    private Long aiQuestionId;

    @Pattern(regexp = "PENDING|ACTIVE|INACTIVE|REVIEWING", message = "Invalid status")
    private String status;
}
```

**영향:** 잘못된 입력 데이터 처리 어려움

---

### 6. **Controller에서 @Valid 검증 누락**
**파일:** `SitterAiProfileController.java:78`

**문제:**
```java
public ResponseEntity<AiProfileResponse> uploadOrUpdateProfile(
    @RequestParam("sitterId") Long sitterId,
    @RequestParam("introVideo") MultipartFile introVideo,
    // ...
)
```

**해결방법:**
```java
public ResponseEntity<AiProfileResponse> uploadOrUpdateProfile(
    @RequestParam("sitterId") @Positive Long sitterId,
    @RequestParam("introVideo") @NotNull MultipartFile introVideo,
    @RequestParam("answerVideo") @NotNull MultipartFile answerVideo,
    @RequestParam("aiQuestionId") @Positive Long aiQuestionId,
    // ...
)
```

---

## 🟢 Minor Issues (선택적 개선)

### 7. **매직 넘버 사용**
**파일:** `SitterAiVideoProfileService.java:52-53`

**문제:**
```java
int sampleSize = Math.min(10, activeQuestions.size());
```

**해결방법:**
```java
private static final int RANDOM_QUESTION_SAMPLE_SIZE = 10;
int sampleSize = Math.min(RANDOM_QUESTION_SAMPLE_SIZE, activeQuestions.size());
```

---

### 8. **보안: 인증/권한 검증 미구현**
**파일:** `SitterAiProfileController.java:79`

**문제:**
```java
@RequestParam("sitterId") Long sitterId  // 누구나 다른 시터의 프로필 수정 가능
```

**해결방법:**
```java
// Authentication에서 시터 ID 추출
@PutMapping(value = "/ai-profile", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public ResponseEntity<AiProfileResponse> uploadOrUpdateProfile(
    @RequestParam("introVideo") MultipartFile introVideo,
    @RequestParam("answerVideo") MultipartFile answerVideo,
    @RequestParam("aiQuestionId") Long aiQuestionId,
    Authentication authentication) {

    Long sitterId = extractSitterIdFromAuthentication(authentication);
    // ...
}
```

---

### 9. **로깅 레벨 개선**
**파일:** `SitterAiVideoProfileService.java:207, 228`

**문제:**
```java
log.warn("Video duration extraction not implemented yet - returning null");
log.warn("S3 upload not implemented yet - returning mock URL: {}", mockUrl);
```

개발 중이므로 warn이 적절하지만, 실제 배포 시 info로 변경 필요.

---

### 10. **응답 코드 개선**
**파일:** `SitterAiProfileController.java` 전체

**문제:**
모든 응답이 `ResponseEntity.ok()` (200 OK)만 사용.

**해결방법:**
```java
// 생성 시
return ResponseEntity.status(HttpStatus.CREATED).body(response);

// 업데이트 시
return ResponseEntity.ok(response);

// 조회 시
return ResponseEntity.ok(response);

// 존재 여부
return ResponseEntity.ok(exists);
```

---

## 📊 코드 품질 평가

| 항목 | 평가 | 비고 |
|------|------|------|
| 아키텍처 설계 | ⭐⭐⭐⭐⭐ | 레이어 분리 우수 |
| 코드 가독성 | ⭐⭐⭐⭐ | 주석 충분, 일부 개선 여지 |
| 에러 처리 | ⭐⭐⭐ | 커스텀 예외 필요 |
| 보안 | ⭐⭐ | 인증/권한 검증 미구현 |
| 테스트 용이성 | ⭐⭐⭐⭐ | 의존성 주입 잘 되어 있음 |
| 확장성 | ⭐⭐⭐⭐ | 인터페이스 기반 설계 |

---

## ✅ 잘된 점

1. **명확한 레이어 분리**: Entity, Repository, Service, Controller가 명확히 분리됨
2. **상세한 주석**: 각 클래스와 메서드에 JavaDoc 스타일 주석 작성
3. **DTO 변환 패턴**: `fromEntity()` 메서드로 일관된 변환 로직
4. **의존성 주입**: `@RequiredArgsConstructor` 사용으로 깔끔한 의존성 관리
5. **Swagger 문서화**: API 문서화를 위한 어노테이션 포함
6. **트랜잭션 관리**: `@Transactional` 적절히 사용
7. **랜덤 질문 분배 로직**: 사용 횟수 기반 균등 분배 알고리즘 우수

---

## 🔧 즉시 수정해야 할 항목 체크리스트

- [ ] `SitterAiVideoProfileRepository.incrementViewCount()`에 `@Modifying` 추가
- [ ] `AiQuestion.questionCategory`를 Enum 타입으로 변경
- [ ] `SitterAiVideoProfile`에서 `@Data` 대신 `@Getter/@Setter` + `@ToString(exclude=...)` 사용
- [ ] 커스텀 예외 클래스 생성 및 적용
- [ ] DTO에 검증 어노테이션 추가 (`@NotNull`, `@Positive` 등)
- [ ] Controller에서 `@Valid` 사용

---

## 🚀 향후 개선 사항

### 단기 (1-2주)
1. S3 실제 업로드 구현
2. FFmpeg 통합하여 영상 길이 추출
3. 인증/권한 검증 구현
4. 전역 예외 핸들러 (`@ControllerAdvice`) 구현
5. 단위 테스트 작성

### 중기 (1개월)
1. 영상 썸네일 자동 생성
2. 영상 트랜스코딩 (HLS/DASH)
3. CDN 연동
4. 조회수 증가 로직 개선 (Redis 캐싱)
5. 통합 테스트 작성

### 장기 (3개월)
1. AI 음성 분석 (감정, 톤, 발음)
2. 영상 품질 자동 검증
3. 관리자 승인 워크플로우
4. 알림 시스템 (이메일/푸시)
5. 성능 테스트 및 최적화

---

## 📝 결론

전체적으로 **잘 설계된 코드**이며, 레이어 분리와 가독성이 우수합니다.
몇 가지 **치명적인 버그**(1, 2번)만 수정하면 바로 테스트 가능합니다.

**권장 우선순위:**
1. Critical Issues 수정 (1-2번)
2. Major Issues 개선 (3-6번)
3. S3/FFmpeg 실제 구현
4. 인증/권한 검증 추가
5. 테스트 코드 작성

---

**검토자:** Claude Code
**검토일:** 2025-11-26
**총 파일 수:** 11개 (Entity 2, Repository 2, DTO 3, Service 1, Controller 1, SQL 2)
