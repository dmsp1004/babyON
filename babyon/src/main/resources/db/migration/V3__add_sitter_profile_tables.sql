-- Sitter Profile System
-- Created: 2025-11-17
-- Description: Creates tables for detailed sitter profiles including certifications, experiences, available times, and service areas

-- ============================================
-- Sitter Profiles Table
-- ============================================
CREATE TABLE sitter_profiles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sitter_id BIGINT NOT NULL UNIQUE,
    profile_image_url VARCHAR(500),
    introduction TEXT,
    available_service_types VARCHAR(500) COMMENT 'Comma-separated: SHORT_TERM,LONG_TERM,LIVE_IN,PICKUP_DROPOFF',
    preferred_age_groups VARCHAR(255) COMMENT 'Comma-separated: INFANT,TODDLER,PRESCHOOL,SCHOOL_AGE',
    languages_spoken VARCHAR(255) COMMENT 'Comma-separated: Korean,English,Chinese,etc',
    education_level VARCHAR(50) COMMENT 'HIGH_SCHOOL,BACHELOR,MASTER,DOCTORATE,etc',
    rating DECIMAL(3,2) DEFAULT 0.0 COMMENT 'Average rating from 0.00 to 5.00',
    total_reviews INT DEFAULT 0,
    profile_completed BOOLEAN DEFAULT FALSE COMMENT 'Whether profile is fully filled out',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Whether profile is active and visible',
    created_at DATETIME(6),
    updated_at DATETIME(6),
    FOREIGN KEY (sitter_id) REFERENCES sitters(id) ON DELETE CASCADE,
    INDEX idx_rating (rating),
    INDEX idx_is_active (is_active),
    INDEX idx_profile_completed (profile_completed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Sitter Certifications Table
-- ============================================
CREATE TABLE sitter_certifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sitter_id BIGINT NOT NULL,
    certification_name VARCHAR(255) NOT NULL,
    issued_by VARCHAR(255),
    issue_date DATE,
    expiry_date DATE,
    certificate_image_url VARCHAR(500),
    description TEXT,
    is_verified BOOLEAN DEFAULT FALSE COMMENT 'Admin verified',
    created_at DATETIME(6),
    updated_at DATETIME(6),
    FOREIGN KEY (sitter_id) REFERENCES sitters(id) ON DELETE CASCADE,
    INDEX idx_sitter_id (sitter_id),
    INDEX idx_is_verified (is_verified)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Sitter Experiences Table
-- ============================================
CREATE TABLE sitter_experiences (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sitter_id BIGINT NOT NULL,
    company_name VARCHAR(255),
    position VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE COMMENT 'Currently working here',
    description TEXT,
    children_age_group VARCHAR(100) COMMENT 'Age group cared for',
    number_of_children INT,
    created_at DATETIME(6),
    updated_at DATETIME(6),
    FOREIGN KEY (sitter_id) REFERENCES sitters(id) ON DELETE CASCADE,
    INDEX idx_sitter_id (sitter_id),
    INDEX idx_start_date (start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Sitter Available Times Table
-- ============================================
CREATE TABLE sitter_available_times (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sitter_id BIGINT NOT NULL,
    day_of_week VARCHAR(20) NOT NULL COMMENT 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY',
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_flexible BOOLEAN DEFAULT FALSE COMMENT 'Flexible with exact times',
    created_at DATETIME(6),
    updated_at DATETIME(6),
    FOREIGN KEY (sitter_id) REFERENCES sitters(id) ON DELETE CASCADE,
    INDEX idx_sitter_id (sitter_id),
    INDEX idx_day_of_week (day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Sitter Service Areas Table
-- ============================================
CREATE TABLE sitter_service_areas (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sitter_id BIGINT NOT NULL,
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    detailed_area VARCHAR(255),
    travel_distance_km INT DEFAULT 5 COMMENT 'Willing to travel distance in km',
    is_primary BOOLEAN DEFAULT FALSE COMMENT 'Primary service area',
    created_at DATETIME(6),
    updated_at DATETIME(6),
    FOREIGN KEY (sitter_id) REFERENCES sitters(id) ON DELETE CASCADE,
    INDEX idx_sitter_id (sitter_id),
    INDEX idx_city_district (city, district)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Sitter Video Resumes Table (for future AI integration)
-- ============================================
CREATE TABLE sitter_video_resumes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sitter_id BIGINT NOT NULL,
    video_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    title VARCHAR(255),
    duration_seconds INT,
    file_size_mb DECIMAL(10,2),
    ai_analysis_result JSON COMMENT 'AI-generated insights (keywords, sentiment, etc)',
    ai_analyzed_at DATETIME(6),
    is_primary BOOLEAN DEFAULT FALSE COMMENT 'Primary video resume',
    view_count INT DEFAULT 0,
    created_at DATETIME(6),
    updated_at DATETIME(6),
    FOREIGN KEY (sitter_id) REFERENCES sitters(id) ON DELETE CASCADE,
    INDEX idx_sitter_id (sitter_id),
    INDEX idx_is_primary (is_primary)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
