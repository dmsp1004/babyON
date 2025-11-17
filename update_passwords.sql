-- Update user passwords with BCrypt hash for "admin123"
UPDATE users SET password = '$2a$10$N9qo8uLOickgx2ZMRZoMye7.Gu1hJLz9QDvEKmRdWQT8u2tBbFQdu' WHERE email = 'admin@babyon.com';
UPDATE users SET password = '$2a$10$N9qo8uLOickgx2ZMRZoMye7.Gu1hJLz9QDvEKmRdWQT8u2tBbFQdu' WHERE email LIKE 'parent%@example.com';
UPDATE users SET password = '$2a$10$N9qo8uLOickgx2ZMRZoMye7.Gu1hJLz9QDvEKmRdWQT8u2tBbFQdu' WHERE email LIKE 'sitter%@example.com';

-- Verify the update
SELECT email, password FROM users WHERE email IN ('admin@babyon.com', 'parent1@example.com', 'sitter1@example.com');
