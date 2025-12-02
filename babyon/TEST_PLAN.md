# babyON AWS S3 통합 테스트 계획

## 📋 시스템 개요

### 구현된 기능
1. **AWS S3 파일 스토리지**
   - S3Client 및 S3Presigner 빈 설정
   - 파일 업로드/다운로드/삭제 기능
   - Presigned URL 생성 (1시간 유효)

2. **시터 AI 화상 이력서 시스템**
   - AI 질문 랜덤 선택 (20개 질문 DB에 저장)
   - 비디오 파일 업로드 (intro + answer)
   - S3 자동 저장 및 Presigned URL 생성
   - 파일 검증 (크기, 타입, 길이)

### 데이터베이스 상태
- **AI Questions**: 20개 활성 질문
- **Test Sitters**:
  - ID 4: sitter1@example.com
  - ID 5: sitter2@example.com
- **S3 Bucket**: babyon-s3-bucket (ap-northeast-2)

---

## 🧪 테스트 시나리오

### 1. 인증 및 JWT 토큰 발급 테스트

#### 1.1 시터 로그인
```bash
curl -X POST http://localhost:8085/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "sitter1@example.com",
    "password": "sitter123"
  }'
```

**Expected Result**:
- Status: 200 OK
- Response: JWT 토큰 반환
- 토큰을 이후 테스트에 사용

---

### 2. AI 질문 조회 테스트

#### 2.1 랜덤 AI 질문 가져오기 (인증 불필요)
```bash
curl -X GET http://localhost:8085/api/v1/sitter/ai-question/random
```

**Expected Result**:
- Status: 200 OK
- Response: AI 질문 정보 (id, questionText, category, difficulty, timeLimitSeconds)
- 질문 ID를 비디오 업로드에 사용

#### 2.2 여러 번 요청하여 랜덤성 확인
```bash
# 5번 반복 실행하여 다른 질문이 나오는지 확인
for i in {1..5}; do
  echo "Request $i:"
  curl -s http://localhost:8085/api/v1/sitter/ai-question/random | grep -o '"id":[0-9]*'
  echo ""
done
```

**Expected Result**:
- 다양한 질문 ID 반환 (사용 횟수가 적은 질문 우선)

---

### 3. 비디오 파일 업로드 테스트

#### 3.1 테스트 비디오 파일 생성
```bash
# 작은 테스트 비디오 파일 생성 (Windows)
# Option 1: 기존 비디오 파일 사용
# Option 2: 온라인에서 샘플 비디오 다운로드
```

#### 3.2 AI 화상 이력서 업로드 (인증 필요)
```bash
JWT_TOKEN="<1.1에서 받은 토큰>"
AI_QUESTION_ID="<2.1에서 받은 질문 ID>"

curl -X PUT http://localhost:8085/api/v1/sitter/ai-profile \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -F "introVideo=@intro.mp4" \
  -F "answerVideo=@answer.mp4" \
  -F "aiQuestionId=$AI_QUESTION_ID"
```

**Expected Result**:
- Status: 200 OK
- Response: 업로드된 프로필 정보
- S3에 파일이 업로드됨 (로그 확인)
- introVideoUrl 및 answerVideoUrl이 S3 키 형태로 저장됨

#### 3.3 파일 검증 테스트

##### a) 잘못된 파일 타입 업로드 (실패 테스트)
```bash
# .txt 파일로 테스트
echo "test" > test.txt

curl -X PUT http://localhost:8085/api/v1/sitter/ai-profile \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -F "introVideo=@test.txt" \
  -F "answerVideo=@test.txt" \
  -F "aiQuestionId=$AI_QUESTION_ID"
```

**Expected Result**:
- Status: 400 Bad Request
- Error: "Invalid file type" 또는 "video/* required"

##### b) 파일 크기 초과 테스트 (실패 테스트)
```bash
# 100MB 이상 파일로 테스트 (있다면)
curl -X PUT http://localhost:8085/api/v1/sitter/ai-profile \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -F "introVideo=@large_video.mp4" \
  -F "answerVideo=@answer.mp4" \
  -F "aiQuestionId=$AI_QUESTION_ID"
```

**Expected Result**:
- Status: 400 Bad Request
- Error: "File size exceeded (max 100MB)"

---

### 4. 프로필 조회 테스트

#### 4.1 내 프로필 조회 (인증 필요)
```bash
curl -X GET http://localhost:8085/api/v1/sitter/ai-profile/me \
  -H "Authorization: Bearer $JWT_TOKEN"
```

**Expected Result**:
- Status: 200 OK
- Response: 프로필 정보
- **introVideoUrl과 answerVideoUrl이 Presigned URL로 변환됨** (중요!)
- Presigned URL은 1시간 동안 유효

#### 4.2 Presigned URL 유효성 확인
```bash
# 4.1에서 받은 Presigned URL을 브라우저에서 열거나 curl로 확인
PRESIGNED_URL="<4.1에서 받은 introVideoUrl>"

curl -I "$PRESIGNED_URL"
```

**Expected Result**:
- Status: 200 OK
- Content-Type: video/mp4
- 비디오 파일 다운로드 가능

#### 4.3 공개 프로필 조회 (인증 불필요)
```bash
curl -X GET http://localhost:8085/api/v1/sitter/ai-profile/4
```

**Expected Result**:
- Status: 200 OK (프로필이 있는 경우)
- Status: 404 Not Found (프로필이 없는 경우)
- Presigned URL 포함

#### 4.4 프로필 존재 여부 확인
```bash
curl -X GET http://localhost:8085/api/v1/sitter/ai-profile/me/exists \
  -H "Authorization: Bearer $JWT_TOKEN"
```

**Expected Result**:
- Status: 200 OK
- Response: true 또는 false

---

### 5. S3 직접 확인 테스트

#### 5.1 AWS CLI로 S3 버킷 확인 (선택사항)
```bash
aws s3 ls s3://babyon-s3-bucket/sitter/ --recursive
```

**Expected Result**:
- 업로드된 비디오 파일 목록 표시
- 파일 경로: `sitter/{sitterId}/ai-profile/{uuid}.mp4`

#### 5.2 S3 콘솔에서 확인
1. AWS Console 로그인
2. S3 서비스 접속
3. `babyon-s3-bucket` 버킷 선택
4. `sitter/` 폴더 확인
5. 업로드된 파일 확인

---

### 6. 통합 시나리오 테스트

#### 전체 플로우
1. 시터 로그인 → JWT 토큰 받기
2. 랜덤 AI 질문 조회 → 질문 ID 받기
3. intro.mp4, answer.mp4 업로드 → S3에 저장
4. 내 프로필 조회 → Presigned URL 확인
5. Presigned URL로 비디오 다운로드 → 재생 가능 확인

---

## ⚠️ 주의사항

### 1. 파일 크기 제한
- 최대 100MB (application.properties 설정)
- Spring Boot: `spring.servlet.multipart.max-file-size=100MB`

### 2. 비디오 길이 제한
- 최대 120초 (현재는 파일 크기 기반 추정)
- TODO: FFmpeg 통합으로 실제 길이 검증 필요

### 3. Presigned URL 유효 기간
- 1시간 (S3Service.java:77)
- 만료 후 재조회 필요

### 4. 보안
- JWT 토큰 필수 (인증이 필요한 엔드포인트)
- SITTER 역할만 업로드 가능
- 본인 프로필만 수정 가능

### 5. AWS 자격 증명
- application-secrets.properties에 저장
- 환경 변수로 관리 권장 (프로덕션)

---

## 🐛 디버깅 팁

### 로그 확인
```bash
# 애플리케이션 로그에서 S3 관련 로그 확인
tail -f logs/application.log | grep -i "s3\|upload\|presigned"
```

### 주요 로그 메시지
- `파일 업로드 성공: bucket=babyon-s3-bucket, key=...`
- `Video uploaded to S3: sitterId=4, videoType=intro, s3Key=...`
- `Presigned URL 생성: key=..., duration=PT1H`

### 데이터베이스 확인
```sql
-- 업로드된 프로필 확인
SELECT * FROM sitter_ai_video_profiles;

-- AI 질문 사용 횟수 확인
SELECT id, LEFT(question_text, 50) as question, usage_count
FROM ai_questions
WHERE is_active = TRUE
ORDER BY usage_count;
```

---

## ✅ 성공 기준

### 필수 테스트
- [x] 로그인 및 JWT 토큰 발급
- [x] 랜덤 AI 질문 조회
- [x] 비디오 파일 S3 업로드
- [x] Presigned URL 생성 및 유효성
- [x] 파일 타입/크기 검증

### 선택 테스트
- [ ] 100MB 이상 파일 업로드 거부
- [ ] 비디오 아닌 파일 업로드 거부
- [ ] Presigned URL 만료 확인 (1시간 후)
- [ ] 동시 다중 업로드 테스트

---

## 📊 테스트 결과 기록

| 테스트 | 상태 | 비고 |
|--------|------|------|
| 로그인 | ⏳ | |
| AI 질문 조회 | ⏳ | |
| 비디오 업로드 | ⏳ | |
| Presigned URL | ⏳ | |
| 파일 검증 | ⏳ | |

---

## 🚀 다음 단계

1. **FFmpeg 통합**: 실제 비디오 길이 검증
2. **썸네일 생성**: 비디오 업로드 시 자동 썸네일
3. **비디오 인코딩**: 표준 포맷으로 자동 변환
4. **CDN 연동**: CloudFront로 빠른 배포
5. **모니터링**: S3 사용량 및 비용 추적
