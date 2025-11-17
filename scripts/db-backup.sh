#!/bin/bash
# DB 백업 스크립트
# 사용법: ./scripts/db-backup.sh

set -e

BACKUP_DIR="./db-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/babyon_backup_$TIMESTAMP.sql"

echo "🔄 Creating backup directory..."
mkdir -p $BACKUP_DIR

echo "📦 Backing up database..."
docker exec babyon-mysql mysqldump \
  -uroot \
  -ptjdrhdgkwk1004^^ \
  --databases babyon_db \
  --add-drop-database \
  --routines \
  --triggers \
  --events \
  > $BACKUP_FILE

echo "✅ Backup created: $BACKUP_FILE"
echo "📊 Backup size: $(du -h $BACKUP_FILE | cut -f1)"

# 최신 백업 파일을 latest.sql로 복사
cp $BACKUP_FILE $BACKUP_DIR/latest.sql
echo "✅ Latest backup updated: $BACKUP_DIR/latest.sql"

# 7일 이상 된 백업 파일 삭제
echo "🧹 Cleaning old backups (older than 7 days)..."
find $BACKUP_DIR -name "babyon_backup_*.sql" -type f -mtime +7 -delete

echo "🎉 Backup completed successfully!"
