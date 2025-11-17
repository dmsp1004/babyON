#!/bin/bash
# DB 복원 스크립트
# 사용법: ./scripts/db-restore.sh [backup-file]
# 예시: ./scripts/db-restore.sh db-backups/latest.sql

set -e

BACKUP_FILE=${1:-"./db-backups/latest.sql"}

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file not found: $BACKUP_FILE"
    echo "Usage: ./scripts/db-restore.sh [backup-file]"
    exit 1
fi

echo "⚠️  WARNING: This will replace all current data in the database!"
echo "Backup file: $BACKUP_FILE"
echo "Backup size: $(du -h $BACKUP_FILE | cut -f1)"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "❌ Restore cancelled"
    exit 0
fi

echo "🔄 Restoring database..."
docker exec -i babyon-mysql mysql \
  -uroot \
  -ptjdrhdgkwk1004^^ \
  < $BACKUP_FILE

echo "✅ Database restored successfully from: $BACKUP_FILE"
echo "🎉 Restore completed!"
