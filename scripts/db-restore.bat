@echo off
REM DB 복원 스크립트 (Windows)
REM 사용법: scripts\db-restore.bat [backup-file]

setlocal

set BACKUP_FILE=%1
if "%BACKUP_FILE%"=="" set BACKUP_FILE=db-backups\latest.sql

if not exist "%BACKUP_FILE%" (
    echo ❌ Error: Backup file not found: %BACKUP_FILE%
    echo Usage: scripts\db-restore.bat [backup-file]
    pause
    exit /b 1
)

echo ⚠️  WARNING: This will replace all current data in the database!
echo Backup file: %BACKUP_FILE%
echo.
set /p confirmation="Are you sure you want to continue? (yes/no): "

if /i not "%confirmation%"=="yes" (
    echo ❌ Restore cancelled
    pause
    exit /b 0
)

echo 🔄 Restoring database...
docker exec -i babyon-mysql mysql -uroot -ptjdrhdgkwk1004^^ < %BACKUP_FILE%

echo ✅ Database restored successfully from: %BACKUP_FILE%
echo 🎉 Restore completed!
pause
