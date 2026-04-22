CREATE TABLE refresh_tokens (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    token      VARCHAR(500)  NOT NULL UNIQUE,
    email      VARCHAR(255)  NOT NULL,
    expires_at DATETIME      NOT NULL,
    created_at DATETIME      DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_token (token),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
