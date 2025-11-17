@echo off
REM DB 백업 스크립트 (Windows)
REM 사용법: scripts\db-backup.bat

setlocal enabledelayedexpansion

set BACKUP_DIR=db-backups
set TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_FILE=%BACKUP_DIR%\babyon_backup_%TIMESTAMP%.sql

echo 🔄 Creating backup directory...
if not exist %BACKUP_DIR% mkdir %BACKUP_DIR%

echo 📦 Backing up database...
docker exec babyon-mysql mysqldump -uroot -ptjdrhdgkwk1004^^ --databases babyon_db --add-drop-database --routines --triggers --events > %BACKUP_FILE%

echo ✅ Backup created: %BACKUP_FILE%

REM 최신 백업을 latest.sql로 복사
copy /Y %BACKUP_FILE% %BACKUP_DIR%\latest.sql >nul
echo ✅ Latest backup updated: %BACKUP_DIR%\latest.sql

echo 🎉 Backup completed successfully!
pause
