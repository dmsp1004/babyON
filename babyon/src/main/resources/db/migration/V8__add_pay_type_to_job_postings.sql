SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'job_postings'
    AND COLUMN_NAME = 'pay_type'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE job_postings ADD COLUMN pay_type ENUM(''HOURLY'', ''DAILY'', ''MONTHLY'') NOT NULL DEFAULT ''HOURLY'' COMMENT ''급여 타입'' AFTER hourly_rate',
    'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;