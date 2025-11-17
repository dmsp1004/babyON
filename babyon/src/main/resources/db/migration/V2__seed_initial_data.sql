-- Seed initial data for development
-- Created: 2025-11-03
-- Description: Creates sample data for testing (parents, sitters, job postings)

-- ============================================
-- Sample Admin User
-- ============================================
-- Password: admin123 (BCrypt hashed)
INSERT IGNORE INTO users (id, email, password, phone_number, user_type, created_at, updated_at, provider, provider_id) VALUES
(1, 'admin@babyon.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', '010-1234-5678', 'ADMIN', NOW(), NOW(), 'LOCAL', NULL);

INSERT IGNORE INTO admins (id, department, admin_level, access_all_records) VALUES
(1, 'Customer Support', 2, true);

-- ============================================
-- Sample Parent Users
-- ============================================
-- Password: parent123 (same as admin123 for testing)
INSERT IGNORE INTO users (id, email, password, phone_number, user_type, created_at, updated_at, provider, provider_id) VALUES
(2, 'parent1@example.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', '010-2345-6789', 'PARENT', NOW(), NOW(), 'LOCAL', NULL),
(3, 'parent2@example.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', '010-3456-7890', 'PARENT', NOW(), NOW(), 'LOCAL', NULL);

INSERT IGNORE INTO parents (id, number_of_children, address, additional_info) VALUES
(2, 2, '서울시 강남구 테헤란로 123', '아이들은 3살, 5살입니다'),
(3, 1, '서울시 송파구 올림픽로 456', '7살 아이 1명');

-- ============================================
-- Sample Sitter Users
-- ============================================
-- Password: sitter123 (same as admin123 for testing)
INSERT IGNORE INTO users (id, email, password, phone_number, user_type, created_at, updated_at, provider, provider_id) VALUES
(4, 'sitter1@example.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', '010-4567-8901', 'SITTER', NOW(), NOW(), 'LOCAL', NULL),
(5, 'sitter2@example.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', '010-5678-9012', 'SITTER', NOW(), NOW(), 'LOCAL', NULL);

INSERT IGNORE INTO sitters (id, sitter_type, experience_years, hourly_rate, bio, is_verified, background_check_completed, interview_completed) VALUES
(4, 'NANNY', 5, 15000, '5년 경력의 베이비시터입니다. 유아교육 전공했습니다.', true, true, true),
(5, 'BABYSITTER', 2, 12000, '아이를 사랑하는 대학생 시터입니다.', false, false, false);

-- ============================================
-- Sample Job Postings
-- ============================================
INSERT IGNORE INTO job_postings (id, title, description, parent_id, location, start_date, end_date, hourly_rate, required_experience_years, is_active, age_of_children, number_of_children, job_type, created_at, updated_at) VALUES
(1, '주말 아이 돌봄 시터 구합니다', '토요일 오후 아이 돌봄을 도와주실 분을 찾습니다.', 2, '서울시 강남구', '2025-11-10 14:00:00', '2025-11-10 18:00:00', 15000, 1, true, '3-5세', 2, 'TEMPORARY', NOW(), NOW()),
(2, '평일 저녁 시터 구해요', '평일 저녁 7시부터 10시까지 아이 돌봄', 3, '서울시 송파구', '2025-11-05 19:00:00', '2025-11-05 22:00:00', 13000, 0, true, '7세', 1, 'PART_TIME', NOW(), NOW());

-- ============================================
-- Sample Job Applications
-- ============================================
INSERT IGNORE INTO job_applications (id, job_posting_id, sitter_id, cover_letter, proposed_hourly_rate, status, created_at, updated_at) VALUES
(1, 1, 4, '안녕하세요! 유아교육 전공자로 5년 경력이 있습니다. 토요일 시간이 됩니다.', 15000, 'PENDING', NOW(), NOW()),
(2, 2, 5, '평일 저녁 시간이 가능합니다. 잘 부탁드립니다!', 12000, 'PENDING', NOW(), NOW());
