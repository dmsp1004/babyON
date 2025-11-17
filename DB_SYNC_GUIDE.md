# 집/회사 PC 간 DB 데이터 동기화 가이드

## 📋 목차
1. [추천 방법](#추천-방법)
2. [방법별 상세 가이드](#방법별-상세-가이드)
3. [FAQ](#faq)

---

## 🎯 추천 방법

### ⭐ 방법 1: 클라우드 DB 사용 (가장 권장)

**무료 서비스:**
- **Supabase**: https://supabase.com (PostgreSQL, 500MB 무료)
- **PlanetScale**: https://planetscale.com (MySQL, 5GB 무료)
- **Railway**: https://railway.app (MySQL/PostgreSQL)
- **Neon**: https://neon.tech (PostgreSQL)

**장점:**
- ✅ 실시간 동기화 (별도 작업 불필요)
- ✅ 어디서든 같은 데이터 접근
- ✅ 실제 프로덕션 환경과 유사
- ✅ 백업/복원 자동화

**사용 방법:**
```bash
# 클라우드 DB 설정 후
docker compose -f docker-compose.cloud.yml up
```

---

### ⭐ 방법 2: Flyway + Seed 데이터 (Git 기반)

**장점:**
- ✅ 모든 데이터가 Git에 버전 관리됨
- ✅ 스키마 + 초기 데이터 모두 관리
- ✅ 팀 협업에 유리

**사용 방법:**
```bash
# 1. Git pull로 최신 마이그레이션 받기
git pull

# 2. Docker 재시작 (자동으로 마이그레이션 실행)
docker compose down -v
docker compose up --build
```

**주의사항:**
- ⚠️ `docker compose down -v`는 기존 데이터를 모두 삭제합니다
- 💡 V2__seed_initial_data.sql에 샘플 데이터가 포함되어 있습니다
- 💡 실제 작업 데이터는 포함되지 않으므로, 테스트 데이터만 동기화됩니다

---

### ⭐ 방법 3: DB 백업/복원 스크립트 (실제 데이터 동기화)

**장점:**
- ✅ 실제 작업 중인 데이터 백업 가능
- ✅ 필요할 때만 수동 동기화
- ✅ Git에 백업 파일 저장 가능 (선택)

**Windows 사용 방법:**

#### 📤 회사에서 백업 생성
```bash
# 1. 백업 생성
scripts\db-backup.bat

# 2. Git에 커밋 (선택)
git add db-backups/latest.sql
git commit -m "chore: update db backup"
git push
```

#### 📥 집에서 복원
```bash
# 1. Git pull (백업을 Git에 저장한 경우)
git pull

# 2. DB 복원
scripts\db-restore.bat

# 또는 특정 백업 파일 지정
scripts\db-restore.bat db-backups\babyon_backup_20251103_150000.sql
```

**Linux/Mac 사용 방법:**
```bash
# 백업
chmod +x scripts/db-backup.sh
./scripts/db-backup.sh

# 복원
chmod +x scripts/db-restore.sh
./scripts/db-restore.sh
```

---

## 📚 방법별 상세 가이드

### 방법 1: 클라우드 DB 설정 (PlanetScale 예시)

#### 1️⃣ PlanetScale 계정 생성
1. https://planetscale.com 접속
2. GitHub 계정으로 가입
3. 무료 플랜 선택

#### 2️⃣ 데이터베이스 생성
1. "Create a database" 클릭
2. 이름: `babyon_db`
3. 리전: `AWS us-east-1` (가장 빠름)

#### 3️⃣ 연결 정보 확인
1. "Connect" 버튼 클릭
2. "Java (Spring Boot)" 선택
3. 연결 정보 복사

#### 4️⃣ docker-compose.cloud.yml 수정
```yaml
environment:
  SPRING_DATASOURCE_URL: jdbc:mysql://your-db.us-east-1.psdb.cloud:3306/babyon_db?sslMode=VERIFY_IDENTITY&serverTimezone=UTC
  SPRING_DATASOURCE_USERNAME: your_username
  SPRING_DATASOURCE_PASSWORD: your_password
```

#### 5️⃣ 실행
```bash
docker compose -f docker-compose.cloud.yml up
```

---

### 방법 2: Flyway Seed 데이터 사용법

#### 📝 샘플 데이터 내용
`V2__seed_initial_data.sql`에 포함된 데이터:

**관리자:**
- 이메일: `admin@babyon.com`
- 비밀번호: `admin123`

**부모 사용자:**
- `parent1@example.com` / `parent123`
- `parent2@example.com` / `parent123`

**시터 사용자:**
- `sitter1@example.com` / `sitter123` (인증 완료)
- `sitter2@example.com` / `sitter123` (미인증)

**구인 공고:** 2개
**지원서:** 2개

#### 🔄 동기화 프로세스
```bash
# 회사 PC에서
git add babyon/src/main/resources/db/migration/
git commit -m "feat: add seed data"
git push

# 집 PC에서
git pull
docker compose down -v
docker compose up --build
```

---

### 방법 3: DB 백업/복원 상세

#### 📦 백업 파일 구조
```
db-backups/
├── latest.sql                      # 최신 백업 (항상 덮어씌워짐)
├── babyon_backup_20251103_100000.sql
├── babyon_backup_20251103_150000.sql
└── babyon_backup_20251104_090000.sql
```

#### ⚙️ 자동 정리
- 7일 이상 된 백업 파일은 자동 삭제됩니다
- `latest.sql`은 항상 최신 상태 유지

#### 🔒 보안 주의사항
DB 백업에는 **모든 데이터 (비밀번호 포함)**가 포함됩니다!

**Git에 백업을 커밋하지 마세요:**
```bash
# .gitignore에 이미 추가되어 있음
db-backups/
```

**안전한 동기화 방법:**
1. Google Drive / Dropbox 사용
2. USB 메모리 사용
3. 회사 내부 파일 서버 사용
4. 암호화 후 Git 저장 (고급)

---

## 🤔 FAQ

### Q1: 어떤 방법을 선택해야 하나요?

**개발 초기 / 테스트용:**
→ **방법 2 (Flyway Seed)** 추천
- Git으로 관리 가능
- 깔끔한 초기화

**실제 작업 데이터 동기화:**
→ **방법 1 (클라우드 DB)** 추천
- 동기화 자동
- 실제 프로덕션 환경과 유사

**가끔 동기화 / 클라우드 사용 불가:**
→ **방법 3 (백업/복원)** 추천
- 수동 제어 가능
- 오프라인 가능

---

### Q2: 백업 파일을 Git에 저장해도 되나요?

**작은 샘플 데이터:** ✅ 괜찮음
**실제 사용자 데이터:** ❌ 절대 안 됨

**이유:**
- 개인정보 보호법 위반 가능
- Git 저장소 크기 급증
- 보안 위험

**대안:**
```bash
# .gitignore에 백업 폴더 추가 (이미 추가되어 있음)
echo "db-backups/" >> .gitignore
```

---

### Q3: Flyway 마이그레이션이 실패해요

**원인 1: 이미 실행된 마이그레이션**
```bash
# 해결: DB 초기화
docker compose down -v
docker compose up
```

**원인 2: SQL 문법 오류**
```bash
# 로그 확인
docker compose logs backend | grep -i flyway
```

**원인 3: 스키마 충돌**
```bash
# 수동으로 DB 접속해서 확인
docker exec -it babyon-mysql mysql -uroot -ptjdrhdgkwk1004^^
USE babyon_db;
SELECT * FROM flyway_schema_history;
```

---

### Q4: 백업/복원이 너무 느려요

**원인:** 데이터가 많을수록 시간이 오래 걸립니다

**해결책:**
```bash
# 압축 백업 (Linux/Mac)
./scripts/db-backup.sh
gzip db-backups/latest.sql

# 압축 복원
gunzip db-backups/latest.sql.gz
./scripts/db-restore.sh db-backups/latest.sql
```

---

### Q5: 클라우드 DB 비용이 걱정돼요

**무료 티어 한도:**
- **PlanetScale:** 5GB 저장소, 10억 row reads/월
- **Supabase:** 500MB 저장소, 2GB 전송/월
- **Railway:** $5 크레딧/월

**개인 프로젝트는 무료로 충분합니다!**

실제 비용 발생 시점:
- 대규모 트래픽 (수천 명 사용자)
- 데이터 10GB 이상

---

### Q6: 로컬 DB와 클라우드 DB를 같이 쓸 수 있나요?

**네, 가능합니다!**

```bash
# 로컬 개발
docker compose up

# 클라우드 DB 테스트
docker compose -f docker-compose.cloud.yml up
```

**추천 워크플로우:**
1. 로컬 DB로 개발/테스트
2. 완성되면 클라우드 DB에 Flyway 마이그레이션 실행
3. 실제 데이터는 클라우드 DB 사용

---

## 🎯 추천 워크플로우

### 시나리오 1: 개발 초기 단계
```bash
# Flyway + Seed 데이터 사용
git pull
docker compose down -v
docker compose up
```

### 시나리오 2: 실제 서비스 개발 중
```bash
# 클라우드 DB 사용
docker compose -f docker-compose.cloud.yml up
```

### 시나리오 3: 네트워크 없을 때
```bash
# 백업/복원 사용
# 회사에서: scripts\db-backup.bat → USB 저장
# 집에서: USB → scripts\db-restore.bat
```

---

## 📞 추가 도움말

문제가 발생하면:
1. Docker 로그 확인: `docker compose logs backend`
2. MySQL 접속 확인: `docker exec -it babyon-mysql mysql -uroot -ptjdrhdgkwk1004^^`
3. Flyway 히스토리: `SELECT * FROM flyway_schema_history;`
