-- AI 화상 이력서 시스템 샘플 데이터
-- 실행 방법: MySQL 클라이언트에서 실행

-- ========================
-- AI 질문 샘플 데이터 (20개)
-- ========================

INSERT INTO ai_questions (question_text, question_category, difficulty_level, time_limit_seconds, is_active, usage_count) VALUES
-- 경험 관련 질문 (EXPERIENCE)
('아이를 돌보면서 가장 보람 있었던 경험은 무엇인가요?', 'EXPERIENCE', 'EASY', 120, TRUE, 0),
('돌봄 중 예상치 못한 위급 상황에 대처한 경험을 말씀해주세요.', 'EXPERIENCE', 'HARD', 120, TRUE, 0),
('다양한 연령대의 아이들을 돌본 경험이 있나요? 각 연령대별로 어떻게 접근하셨나요?', 'EXPERIENCE', 'MEDIUM', 120, TRUE, 0),
('부모님과 의견이 달랐던 적이 있나요? 어떻게 해결하셨나요?', 'EXPERIENCE', 'MEDIUM', 120, TRUE, 0),

-- 성격 및 자질 관련 질문 (PERSONALITY)
('본인의 강점 3가지를 말씀해주세요.', 'PERSONALITY', 'EASY', 120, TRUE, 0),
('스트레스를 받을 때 어떻게 관리하시나요?', 'PERSONALITY', 'MEDIUM', 120, TRUE, 0),
('왜 아이 돌봄 일을 시작하게 되셨나요?', 'PERSONALITY', 'EASY', 120, TRUE, 0),
('본인을 한 단어로 표현한다면 무엇인가요? 그 이유는?', 'PERSONALITY', 'EASY', 120, TRUE, 0),

-- 상황 대처 질문 (SITUATION)
('아이가 갑자기 심하게 울기 시작한다면 어떻게 대처하시겠습니까?', 'SITUATION', 'MEDIUM', 120, TRUE, 0),
('아이가 밥을 먹지 않으려고 한다면 어떻게 하시겠습니까?', 'SITUATION', 'EASY', 120, TRUE, 0),
('두 아이가 장난감을 두고 싸운다면 어떻게 중재하시겠습니까?', 'SITUATION', 'MEDIUM', 120, TRUE, 0),
('아이가 낯선 사람을 무서워한다면 어떻게 도와주시겠습니까?', 'SITUATION', 'MEDIUM', 120, TRUE, 0),

-- 동기 및 열정 (MOTIVATION)
('5년 후 본인의 모습은 어떨 것 같나요?', 'MOTIVATION', 'MEDIUM', 120, TRUE, 0),
('이 일을 계속하고 싶은 이유는 무엇인가요?', 'MOTIVATION', 'EASY', 120, TRUE, 0),
('가장 이상적인 근무 환경은 어떤 것인가요?', 'MOTIVATION', 'EASY', 120, TRUE, 0),

-- 육아 철학 (CHILDCARE)
('아이의 창의력을 키우기 위해 어떤 활동을 계획하시겠습니까?', 'CHILDCARE', 'MEDIUM', 120, TRUE, 0),
('훈육이 필요한 상황에서 어떻게 접근하시나요?', 'CHILDCARE', 'HARD', 120, TRUE, 0),
('아이의 안전을 지키기 위해 가장 중요하게 생각하는 것은 무엇인가요?', 'CHILDCARE', 'MEDIUM', 120, TRUE, 0),
('아이와 신뢰 관계를 쌓기 위해 어떤 노력을 하시나요?', 'CHILDCARE', 'MEDIUM', 120, TRUE, 0),
('아이의 발달 단계에 맞는 놀이 활동을 어떻게 선택하시나요?', 'CHILDCARE', 'HARD', 120, TRUE, 0);

-- 삽입 확인
SELECT COUNT(*) as total_questions FROM ai_questions WHERE is_active = TRUE;
SELECT question_category, COUNT(*) as count
FROM ai_questions
WHERE is_active = TRUE
GROUP BY question_category;
