-- Flyway Migration Repair Script
-- Purpose: Fix failed migration V2 in flyway_schema_history
-- Date: 2025-11-05

-- Step 1: Check current Flyway history
SELECT
    installed_rank,
    version,
    description,
    success,
    installed_on
FROM flyway_schema_history
ORDER BY installed_rank;

-- Step 2: Delete the failed migration record
-- This removes the failed V2 migration from history so it can be re-run
DELETE FROM flyway_schema_history
WHERE version = '2' AND success = 0;

-- Step 3: Clean up any partial data from V2 (if needed)
-- Uncomment these lines if V2 partially inserted data before failing
-- Be careful: This will delete ALL data in these tables!

-- SET FOREIGN_KEY_CHECKS = 0;
-- TRUNCATE TABLE job_applications;
-- TRUNCATE TABLE job_postings;
-- TRUNCATE TABLE sitters;
-- TRUNCATE TABLE parents;
-- TRUNCATE TABLE admins;
-- TRUNCATE TABLE users;
-- SET FOREIGN_KEY_CHECKS = 1;

-- Step 4: Verify the fix
SELECT
    installed_rank,
    version,
    description,
    success,
    installed_on
FROM flyway_schema_history
ORDER BY installed_rank;

-- After running this script:
-- 1. Restart your Spring Boot application
-- 2. Flyway will re-run migration V2
-- 3. Check logs to ensure V2 completes successfully
