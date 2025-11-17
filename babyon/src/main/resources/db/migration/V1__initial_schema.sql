-- Initial schema for babyON childcare matching platform
-- Created: 2025-11-03
-- Description: Creates tables for users (parents, sitters, admins), job postings, and job applications

-- ============================================
-- Users Table (Parent table for inheritance)
-- ============================================
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50),
    user_type VARCHAR(50),
    created_at DATETIME(6),
    updated_at DATETIME(6),
    provider VARCHAR(50),
    provider_id VARCHAR(255),
    INDEX idx_email (email),
    INDEX idx_user_type (user_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Parents Table (Joined inheritance)
-- ============================================
CREATE TABLE parents (
    id BIGINT PRIMARY KEY,
    number_of_children INT,
    address VARCHAR(500),
    additional_info TEXT,
    FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Sitters Table (Joined inheritance)
-- ============================================
CREATE TABLE sitters (
    id BIGINT PRIMARY KEY,
    sitter_type VARCHAR(50),
    experience_years INT,
    hourly_rate DOUBLE,
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    background_check_completed BOOLEAN DEFAULT FALSE,
    interview_completed BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sitter_type (sitter_type),
    INDEX idx_is_verified (is_verified)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Admins Table (Joined inheritance)
-- ============================================
CREATE TABLE admins (
    id BIGINT PRIMARY KEY,
    department VARCHAR(255),
    admin_level INT DEFAULT 1,
    access_all_records BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Job Postings Table
-- ============================================
CREATE TABLE job_postings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    parent_id BIGINT NOT NULL,
    location VARCHAR(500),
    start_date DATETIME(6),
    end_date DATETIME(6),
    hourly_rate DOUBLE,
    required_experience_years INT,
    is_active BOOLEAN DEFAULT TRUE,
    age_of_children VARCHAR(255),
    number_of_children INT,
    job_type VARCHAR(50),
    created_at DATETIME(6),
    updated_at DATETIME(6),
    FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE CASCADE,
    INDEX idx_parent_id (parent_id),
    INDEX idx_is_active (is_active),
    INDEX idx_job_type (job_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Job Applications Table
-- ============================================
CREATE TABLE job_applications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    job_posting_id BIGINT NOT NULL,
    sitter_id BIGINT NOT NULL,
    cover_letter TEXT,
    proposed_hourly_rate DOUBLE,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at DATETIME(6),
    updated_at DATETIME(6),
    FOREIGN KEY (job_posting_id) REFERENCES job_postings(id) ON DELETE CASCADE,
    FOREIGN KEY (sitter_id) REFERENCES sitters(id) ON DELETE CASCADE,
    INDEX idx_job_posting_id (job_posting_id),
    INDEX idx_sitter_id (sitter_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    UNIQUE KEY uk_job_sitter (job_posting_id, sitter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
