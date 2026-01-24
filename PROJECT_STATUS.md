# babyON - AI 기반 아이 돌봄 매칭 플랫폼

## 프로젝트 개요

**babyON**은 부모와 전문 시터를 연결하는 AI 기반 아이 돌봄 매칭 플랫폼입니다.

### 주요 특징
- 단기/장기/입주/등하원 도우미 등 다양한 형태의 시터 고용 중개
- AI 기반 화상 이력서 시스템으로 시터 사전 검증
- JWT 기반 인증 및 OAuth2 소셜 로그인 지원
- 모바일(Android/iOS) 및 웹 지원

---

## 기술 스택

### Backend (Spring Boot)
| 기술 | 버전 | 용도 |
|------|------|------|
| Java | 17 | 런타임 |
| Spring Boot | 3.4.3 | 프레임워크 |
| Spring Security | - | 인증/인가 |
| Spring Data JPA | - | ORM |
| MySQL | 8.0 | 데이터베이스 |
| Flyway | - | DB 마이그레이션 |
| JWT (jjwt) | 0.11.5 | 토큰 인증 |
| AWS S3 SDK | 2.20.26 | 영상 파일 저장 |
| Swagger | 2.3.0 | API 문서 |

### Frontend (Flutter)
| 기술 | 버전 | 용도 |
|------|------|------|
| Dart SDK | ^3.7.0 | 런타임 |
| Provider | 6.0.5 | 상태 관리 |
| Dio | 5.1.1 | HTTP 클라이언트 |
| Camera | 0.10.5+5 | 카메라 녹화 |
| Video Player | 2.8.1 | 비디오 재생 |
| Flutter Secure Storage | 8.0.0 | 토큰 보안 저장 |

---

## 프로젝트 구조

```
babyON/
├── babyon/                     # Spring Boot 백엔드
│   ├── src/main/java/com/babyon/childcare/
│   │   ├── config/             # 보안, CORS, S3 설정
│   │   ├── controller/         # REST API (8개 컨트롤러)
│   │   ├── service/            # 비즈니스 로직 (7개 서비스)
│   │   ├── repository/         # JPA Repository
│   │   ├── entity/             # 데이터베이스 엔티티
│   │   ├── dto/                # 요청/응답 DTO
│   │   ├── security/           # JWT 필터, 인증
│   │   └── exception/          # 예외 처리
│   ├── src/main/resources/
│   │   ├── application.properties
│   │   └── db/migration/       # Flyway 마이그레이션 (5개)
│   ├── build.gradle
│   └── Dockerfile
│
├── babyon_app/                 # Flutter 모바일/웹 앱
│   ├── lib/
│   │   ├── main.dart           # 앱 진입점
│   │   ├── models/             # 데이터 모델
│   │   ├── providers/          # 상태 관리 (AuthProvider)
│   │   ├── services/           # API 서비스
│   │   └── screens/            # UI 화면 (17개)
│   │       ├── auth/           # 로그인, 회원가입
│   │       ├── job_posting_*   # 구인글 관련
│   │       ├── job_application_* # 지원 관련
│   │       ├── *_home_screen   # 역할별 홈 화면
│   │       └── ai_video_*      # AI 화상 이력서
│   ├── android/                # Android 설정
│   ├── ios/                    # iOS 설정
│   └── pubspec.yaml
│
├── docker-compose.yml          # Docker 구성
├── CLAUDE.md                   # Claude 지시사항
└── PROJECT_STATUS.md           # 이 문서
```

---

## 구현 완료 기능

### 1. 사용자 인증 (100%)
- [x] 이메일/비밀번호 회원가입
- [x] 이메일/비밀번호 로그인
- [x] JWT 토큰 발급 및 검증
- [x] 자동 로그인 (SecureStorage)
- [x] 토큰 만료 시 자동 삭제
- [x] OAuth2 설정 (Google, Kakao, Naver) - API만 구현

### 2. 구인/구직 시스템 (100%)
- [x] 구인글 CRUD (생성, 조회, 수정, 삭제)
- [x] 구인글 검색 (제목, 설명, 지역)
- [x] 구인글 페이지네이션 및 정렬
- [x] 지원서 생성 및 조회
- [x] 지원서 철회
- [x] 내 구인글/지원 목록 조회

### 3. 프로필 시스템 (100%)
- [x] 부모 프로필 조회/수정
- [x] 시터 프로필 조회/수정
- [x] 자격증, 경력, 가능 시간대, 서비스 지역 관리

### 4. AI 화상 이력서 (100%)
- [x] 자유 소개 영상 녹화 (최대 120초)
- [x] AI 질문 랜덤 선택 (5개 카테고리)
- [x] AI 질문 답변 영상 녹화
- [x] 비디오 미리보기
- [x] AWS S3 업로드 API

### 5. UI 화면 (17개 완료)
| 화면 | 파일명 | 사용자 |
|------|--------|--------|
| 로그인 | `login_screen.dart` | 전체 |
| 회원가입 | `register_screen.dart` | 전체 |
| 부모 홈 | `parent_home_screen.dart` | Parent |
| 시터 홈 | `sitter_home_screen.dart` | Sitter |
| 관리자 홈 | `admin_home_screen.dart` | Admin |
| 구인글 목록 | `job_posting_list_screen.dart` | 전체 |
| 구인글 상세 | `job_posting_detail_screen.dart` | 전체 |
| 구인글 작성 | `create_job_posting_screen.dart` | Parent |
| 구인글 수정 | `edit_job_posting_screen.dart` | Parent |
| 지원 목록 | `job_application_list_screen.dart` | 전체 |
| 지원서 작성 | `create_job_application_screen.dart` | Sitter |
| 부모 프로필 | `parent_profile_screen.dart` | Parent |
| 시터 프로필 | `sitter_profile_edit_screen.dart` | Sitter |
| AI 이력서 등록 | `ai_video_resume_flow_screen.dart` | Sitter |
| 비디오 녹화 | `video_recording_screen.dart` | Sitter |
| 비디오 미리보기 | `video_preview_screen.dart` | Sitter |

---

## API 엔드포인트

### 인증 API
```
POST /api/v1/auth/register     - 회원가입
POST /api/v1/auth/login        - 로그인
GET  /api/v1/auth/validate-token - 토큰 검증
```

### 구인글 API
```
GET    /api/job-postings           - 목록 조회 (페이지네이션)
GET    /api/job-postings/{id}      - 상세 조회
POST   /api/job-postings           - 생성 (Parent)
PUT    /api/job-postings/{id}      - 수정
DELETE /api/job-postings/{id}      - 삭제
GET    /api/job-postings/search    - 검색
GET    /api/job-postings/my-postings - 내 구인글
```

### 지원 API
```
POST   /api/job-applications              - 지원 (Sitter)
DELETE /api/job-applications/{id}         - 철회
GET    /api/job-applications/my-applications - 내 지원
GET    /api/job-applications/by-posting/{id} - 구인글별 지원
GET    /api/job-applications/all-for-parent  - 부모용 전체 지원
```

### AI 화상 이력서 API
```
GET  /api/v1/sitter/ai-question/random  - 랜덤 질문
PUT  /api/v1/sitter/ai-profile          - 업로드
GET  /api/v1/sitter/ai-profile/me       - 내 프로필
GET  /api/v1/sitter/ai-profile/{id}     - 시터 프로필
GET  /api/v1/sitter/ai-profile/me/exists - 존재 여부
```

---

## 모바일 테스트 설정

### Android 권한 (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

### iOS 권한 (Info.plist)
```xml
NSCameraUsageDescription - 카메라 접근
NSMicrophoneUsageDescription - 마이크 접근
NSPhotoLibraryUsageDescription - 사진 라이브러리 접근
```

### 서버 연결 설정 (api_service.dart)
```dart
// 현재 설정: Docker 환경 (8081)
static const int _serverPort = 8081;

// Android 에뮬레이터: http://10.0.2.2:8081/api
// iOS 시뮬레이터: http://localhost:8081/api
// 로컬 실행 시: 8085로 변경 필요
```

---

## 실행 방법

### 1. 백엔드 (Docker)
```bash
cd babyON
docker-compose up -d
# MySQL: 3307, Backend: 8081
```

### 2. 백엔드 (로컬)
```bash
cd babyon
./gradlew bootRun
# http://localhost:8085
# api_service.dart에서 _serverPort = 8085로 변경 필요
```

### 3. Flutter 앱
```bash
cd babyon_app
flutter pub get
flutter run
# Android/iOS 에뮬레이터 또는 실제 디바이스
```

### 4. Swagger UI (API 문서)
```
http://localhost:8085/swagger-ui.html  # 로컬
http://localhost:8081/swagger-ui.html  # Docker
```

---

## 주의사항 및 수정 필요 항목

### 1. 앱 이름 변경 필요
- Android: `AndroidManifest.xml`에서 `android:label="ida_app"` → `"babyON"`
- iOS: `Info.plist`에서 `CFBundleDisplayName` → `"babyON"`

### 2. 서버 포트 설정
- `api_service.dart`: `_serverPort` 값 확인
  - Docker 사용 시: `8081`
  - 로컬 실행 시: `8085`

### 3. 프로덕션 배포 전 필수 변경
- `JWT_SECRET`: 환경변수로 안전한 값 설정
- AWS 자격증명: 환경변수로 설정
- CORS: 프로덕션 도메인으로 제한
- OAuth2: 실제 클라이언트 ID/Secret 설정

### 4. 폰트 설정 (pubspec.yaml)
현재 같은 파일이 weight별로 중복 설정됨:
```yaml
fonts:
  - family: NotoSansKR
    fonts:
      - asset: assets/fonts/NotoSansKR-Regular.ttf
      - asset: assets/fonts/NotoSansKR-Medium.ttf    # 추가 필요
        weight: 500
      - asset: assets/fonts/NotoSansKR-Bold.ttf      # 추가 필요
        weight: 700
```

---

## 데이터베이스 스키마

### 주요 테이블
| 테이블 | 설명 |
|--------|------|
| `users` | 모든 사용자 (부모, 시터, 관리자) |
| `parents` | 부모 정보 |
| `sitters` | 시터 정보 |
| `job_postings` | 구인글 |
| `job_applications` | 지원서 |
| `sitter_profiles` | 시터 프로필 |
| `sitter_certifications` | 시터 자격증 |
| `sitter_experiences` | 시터 경력 |
| `sitter_available_times` | 시터 가능 시간 |
| `sitter_service_areas` | 시터 서비스 지역 |
| `ai_questions` | AI 면접 질문 |
| `sitter_ai_video_profiles` | AI 화상 이력서 |

### Flyway 마이그레이션
1. `V1__initial_schema.sql` - 초기 스키마
2. `V2__seed_initial_data.sql` - 테스트 데이터
3. `V3__add_sitter_profile_tables.sql` - 시터 프로필
4. `V4__add_ai_video_profile_tables.sql` - AI 화상 이력서
5. `V5__seed_ai_questions_data.sql` - AI 질문 데이터

---

## 향후 개발 예정

- [ ] OAuth2 소셜 로그인 UI 연동
- [ ] 실시간 채팅 기능
- [ ] 결제 시스템 연동
- [ ] 푸시 알림
- [ ] 리뷰/평점 시스템
- [ ] 관리자 대시보드
- [ ] AI 분석 리포트 (화상 이력서 기반)

---

## 문의 및 지원

이 문서는 Claude AI 어시스턴트와의 협업을 위해 작성되었습니다.
프로젝트 관련 질문이나 수정이 필요한 경우 이 문서를 참조하세요.

**마지막 업데이트:** 2026-01-24
