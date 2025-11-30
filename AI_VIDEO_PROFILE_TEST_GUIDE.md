# AI 화상 이력서 시스템 테스트 가이드

## 목차
1. [환경 설정](#1-환경-설정)
2. [데이터베이스 준비](#2-데이터베이스-준비)
3. [Spring Boot 실행](#3-spring-boot-실행)
4. [API 테스트](#4-api-테스트)

---

## 1. 환경 설정

### 필요 사항
- Java 17 이상
- MySQL 8.0 이상
- Postman 또는 cURL
- 테스트용 영상 파일 2개 (각각 최대 120초, MP4/MOV 형식)

---

## 2. 데이터베이스 준비

### 2.1 MySQL 접속
```bash
# MySQL Shell 사용 (Windows)
"/c/Program Files/MySQL/MySQL Shell 8.0/bin/mysqlsh" --sql -u root -ptjdrhdgkwk1004^^ -h localhost -P 3306 -D babyon_db

# 또는 일반 MySQL 클라이언트
mysql -u root -p babyon_db
```

### 2.2 테이블 생성
```bash
# DDL 실행 (프로젝트 루트에서)
mysql -u root -p babyon_db < src/main/resources/db/migration/ai_video_profile_ddl.sql
```

**또는 MySQL Shell에서 직접 실행:**
```sql
-- src/main/resources/db/migration/ai_video_profile_ddl.sql 파일 내용 복사/붙여넣기
```

### 2.3 샘플 데이터 삽입
```bash
# 샘플 데이터 실행
mysql -u root -p babyon_db < src/main/resources/db/migration/ai_video_profile_sample_data.sql
```

### 2.4 데이터 확인
```sql
-- 질문 개수 확인
SELECT COUNT(*) FROM ai_questions WHERE is_active = TRUE;

-- 질문 목록 확인
SELECT id, question_text, question_category, difficulty_level
FROM ai_questions
WHERE is_active = TRUE
LIMIT 5;

-- 테이블 구조 확인
DESCRIBE ai_questions;
DESCRIBE sitter_ai_video_profiles;
```

---

## 3. Spring Boot 실행

### 3.1 프로젝트 빌드 및 실행
```bash
# Windows (프로젝트 루트에서)
cd C:\Users\user\IdeaProjects\babyON\babyon

# Gradle 빌드 및 실행
./gradlew bootRun

# 또는 IntelliJ IDEA에서 실행
```

### 3.2 실행 확인
서버가 정상적으로 시작되면 다음 로그를 확인:
```
Started ChildcareApplication in X.XXX seconds
```

기본 포트: `http://localhost:8080`

---

## 4. API 테스트

### 4.1 랜덤 AI 질문 조회

**Endpoint:** `GET /api/v1/sitter/ai-question/random`

**cURL 예제:**
```bash
curl -X GET "http://localhost:8080/api/v1/sitter/ai-question/random" \
  -H "Content-Type: application/json"
```

**예상 응답:**
```json
{
  "questionId": 1,
  "questionText": "아이를 돌보면서 가장 보람 있었던 경험은 무엇인가요?",
  "questionCategory": "EXPERIENCE",
  "difficultyLevel": "EASY",
  "timeLimitSeconds": 120
}
```

**Postman 설정:**
- Method: `GET`
- URL: `http://localhost:8080/api/v1/sitter/ai-question/random`
- Headers:
  - `Content-Type: application/json`

---

### 4.2 AI 화상 이력서 업로드

**Endpoint:** `PUT /api/v1/sitter/ai-profile`

**준비사항:**
1. 테스트용 영상 파일 2개 준비 (intro.mp4, answer.mp4)
2. 시터 ID 확인 (예: `1`)
3. AI 질문 ID 확인 (위 API에서 받은 questionId)

**cURL 예제:**
```bash
curl -X PUT "http://localhost:8080/api/v1/sitter/ai-profile" \
  -H "Content-Type: multipart/form-data" \
  -F "sitterId=1" \
  -F "introVideo=@C:/path/to/intro.mp4" \
  -F "answerVideo=@C:/path/to/answer.mp4" \
  -F "aiQuestionId=1" \
  -F "status=ACTIVE"
```

**Postman 설정:**
1. Method: `PUT`
2. URL: `http://localhost:8080/api/v1/sitter/ai-profile`
3. Body 탭 선택 → `form-data` 선택
4. 다음 키-값 쌍 추가:

| Key | Type | Value |
|-----|------|-------|
| sitterId | Text | `1` |
| introVideo | File | (파일 선택) |
| answerVideo | File | (파일 선택) |
| aiQuestionId | Text | `1` |
| status | Text | `ACTIVE` (선택 사항) |

**예상 응답:**
```json
{
  "sitterId": 1,
  "introVideoUrl": "https://s3.amazonaws.com/babyon/sitter/1/ai-profile/intro-1234567890.mp4",
  "introVideoDurationSeconds": null,
  "aiQuestion": {
    "questionId": 1,
    "questionText": "아이를 돌보면서 가장 보람 있었던 경험은 무엇인가요?",
    "questionCategory": "EXPERIENCE",
    "difficultyLevel": "EASY",
    "timeLimitSeconds": 120
  },
  "answerVideoUrl": "https://s3.amazonaws.com/babyon/sitter/1/ai-profile/answer-1234567890.mp4",
  "answerVideoDurationSeconds": null,
  "status": "ACTIVE",
  "viewCount": 0,
  "createdAt": "2025-11-26T10:30:45",
  "updatedAt": "2025-11-26T10:30:45"
}
```

**주의사항:**
- 현재 S3 업로드는 Mock URL을 반환합니다 (실제 파일은 업로드되지 않음)
- 영상 길이 검증도 현재 비활성화 상태입니다 (null 반환)
- 실제 구현 시 S3Service와 FFmpeg 통합 필요

---

### 4.3 AI 화상 이력서 조회

**Endpoint:** `GET /api/v1/sitter/ai-profile/{sitterId}`

**cURL 예제:**
```bash
curl -X GET "http://localhost:8080/api/v1/sitter/ai-profile/1" \
  -H "Content-Type: application/json"
```

**Postman 설정:**
- Method: `GET`
- URL: `http://localhost:8080/api/v1/sitter/ai-profile/1`

**예상 응답:** (4.2와 동일한 형식)

---

### 4.4 AI 화상 이력서 존재 여부 확인

**Endpoint:** `GET /api/v1/sitter/ai-profile/{sitterId}/exists`

**cURL 예제:**
```bash
curl -X GET "http://localhost:8080/api/v1/sitter/ai-profile/1/exists" \
  -H "Content-Type: application/json"
```

**예상 응답:**
```json
true
```

또는 (등록하지 않은 경우)
```json
false
```

---

## 5. 데이터베이스 검증

API 호출 후 데이터베이스에서 직접 확인:

```sql
-- AI 화상 이력서 확인
SELECT * FROM sitter_ai_video_profiles WHERE sitter_id = 1;

-- 질문 사용 횟수 확인
SELECT id, question_text, usage_count
FROM ai_questions
ORDER BY usage_count DESC;

-- 통계 확인
SELECT status, COUNT(*) as count
FROM sitter_ai_video_profiles
GROUP BY status;
```

---

## 6. 오류 처리 테스트

### 6.1 존재하지 않는 시터 ID로 업로드 시도
```bash
curl -X PUT "http://localhost:8080/api/v1/sitter/ai-profile" \
  -F "sitterId=99999" \
  -F "introVideo=@intro.mp4" \
  -F "answerVideo=@answer.mp4" \
  -F "aiQuestionId=1"
```
**예상:** `Sitter not found with ID: 99999` 오류

### 6.2 존재하지 않는 질문 ID로 업로드 시도
```bash
curl -X PUT "http://localhost:8080/api/v1/sitter/ai-profile" \
  -F "sitterId=1" \
  -F "introVideo=@intro.mp4" \
  -F "answerVideo=@answer.mp4" \
  -F "aiQuestionId=99999"
```
**예상:** `AI question not found or inactive: 99999` 오류

### 6.3 비디오 파일 없이 업로드 시도
```bash
curl -X PUT "http://localhost:8080/api/v1/sitter/ai-profile" \
  -F "sitterId=1" \
  -F "aiQuestionId=1"
```
**예상:** 파일 필수 오류

---

## 7. Swagger UI를 통한 테스트 (선택 사항)

Swagger가 설정되어 있다면:

1. 브라우저에서 접속: `http://localhost:8080/swagger-ui.html`
2. "Sitter AI Video Profile" 섹션 찾기
3. API를 직접 테스트

---

## 8. TODO: 실제 구현 전 확인 사항

현재 스켈레톤 코드의 제한 사항:

- [ ] S3 실제 업로드 미구현 (Mock URL 반환)
- [ ] 영상 길이 검증 미구현 (항상 null)
- [ ] 인증/권한 검증 미구현
- [ ] 파일 크기만 체크 (실제 영상 메타데이터 미추출)

실제 운영 전 구현 필요:
1. AWS S3 SDK 통합 및 파일 업로드
2. FFmpeg를 통한 영상 길이 추출
3. Spring Security를 통한 인증/권한 검증
4. 파일 형식 및 코덱 검증
5. 예외 처리 및 에러 메시지 개선

---

## 9. 문제 해결

### 9.1 "Sitter not found" 오류
- 해결: sitters 테이블에 테스트용 시터 데이터가 있는지 확인
```sql
SELECT id, name, email FROM sitters LIMIT 5;
```

### 9.2 "No active AI questions available" 오류
- 해결: ai_questions 테이블에 데이터가 있는지 확인
```sql
SELECT COUNT(*) FROM ai_questions WHERE is_active = TRUE;
```

### 9.3 Connection refused
- 해결: Spring Boot 애플리케이션이 실행 중인지 확인
- 포트 8080이 다른 프로세스에 의해 사용 중인지 확인

---

## 10. 테스트 체크리스트

- [ ] 데이터베이스 테이블 생성 완료
- [ ] 샘플 AI 질문 데이터 삽입 완료
- [ ] Spring Boot 애플리케이션 정상 실행
- [ ] 랜덤 질문 조회 API 테스트 성공
- [ ] AI 화상 이력서 업로드 API 테스트 성공
- [ ] AI 화상 이력서 조회 API 테스트 성공
- [ ] 존재 여부 확인 API 테스트 성공
- [ ] 데이터베이스에서 데이터 확인 완료

---

## 참고
- Entity 위치: `src/main/java/com/babyon/childcare/entity/`
- Controller 위치: `src/main/java/com/babyon/childcare/controller/SitterAiProfileController.java`
- Service 위치: `src/main/java/com/babyon/childcare/service/SitterAiVideoProfileService.java`
