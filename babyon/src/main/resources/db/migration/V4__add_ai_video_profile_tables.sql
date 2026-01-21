-- AI 화상 이력서 시스템 데이터베이스 테이블 생성
-- 실행 방법: MySQL 클라이언트에서 실행하거나 application.properties에 설정

-- ========================
-- 1. AI 질문 테이블
-- ========================
CREATE TABLE IF NOT EXISTS ai_questions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    question_text TEXT NOT NULL COMMENT 'AI 질문 내용',
    question_category VARCHAR(50) COMMENT '질문 카테고리 (EXPERIENCE, PERSONALITY, SITUATION, MOTIVATION, CHILDCARE)',
    difficulty_level VARCHAR(20) COMMENT '난이도 (EASY, MEDIUM, HARD)',
    time_limit_seconds INT NOT NULL DEFAULT 120 COMMENT '답변 시간 제한 (초)',
    is_active BOOLEAN DEFAULT TRUE COMMENT '활성화 상태',
    usage_count INT DEFAULT 0 COMMENT '사용 횟수',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active_usage (is_active, usage_count),
    INDEX idx_category (question_category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI 화상 이력서용 질문 테이블';

-- ========================
-- 2. 시터 AI 화상 이력서 테이블
-- ========================
CREATE TABLE IF NOT EXISTS sitter_ai_video_profiles (
    sitter_id BIGINT PRIMARY KEY COMMENT '시터 ID (PK, FK)',
    intro_video_url VARCHAR(500) COMMENT '자유 소개 영상 S3 URL',
    intro_video_duration_seconds INT COMMENT '인트로 영상 길이 (초, 최대 120초)',
    ai_question_id BIGINT COMMENT '답변한 AI 질문 ID',
    answer_video_url VARCHAR(500) COMMENT 'AI 질문 답변 영상 S3 URL',
    answer_video_duration_seconds INT COMMENT '답변 영상 길이 (초, 최대 120초)',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT '프로필 상태 (PENDING, ACTIVE, INACTIVE, REVIEWING)',
    view_count INT DEFAULT 0 COMMENT '조회수',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sitter_id) REFERENCES sitters(id) ON DELETE CASCADE,
    FOREIGN KEY (ai_question_id) REFERENCES ai_questions(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_question (ai_question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='시터 AI 화상 이력서 테이블';
