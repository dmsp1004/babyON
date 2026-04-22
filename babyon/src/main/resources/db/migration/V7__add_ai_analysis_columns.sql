-- AI 분석 결과 컬럼 추가
ALTER TABLE sitter_ai_video_profiles
    ADD COLUMN ai_analysis_result JSON         NULL COMMENT 'AI 분석 결과 (JSON)',
    ADD COLUMN ai_analyzed_at     DATETIME     NULL COMMENT 'AI 분석 완료 시각';

-- ANALYZING 상태를 수용하기 위해 status 컬럼 ENUM 확장
-- MySQL ENUM은 ALTER로 값 추가 가능
ALTER TABLE sitter_ai_video_profiles
    MODIFY COLUMN status ENUM('PENDING', 'ANALYZING', 'ACTIVE', 'INACTIVE', 'REVIEWING')
        NOT NULL DEFAULT 'PENDING' COMMENT '이력서 상태';
