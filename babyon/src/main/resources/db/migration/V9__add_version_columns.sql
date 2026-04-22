-- Optimistic locking: version 컬럼 추가
-- 동시 수정 충돌을 감지하여 마지막 커밋 승리(last-write-wins) 문제를 방지한다.

ALTER TABLE job_postings
    ADD COLUMN version BIGINT NOT NULL DEFAULT 0;

-- parents 테이블은 JOINED 상속 전략으로 users와 PK를 공유하는 별도 테이블이다.
ALTER TABLE parents
    ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
