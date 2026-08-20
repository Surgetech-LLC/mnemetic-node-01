#!/bin/bash

set -euo pipefail

BACKUP_DIR="$(dirname "$0")/archives"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/mnemetic-postgres-$TIMESTAMP.sql"

mkdir -p "$BACKUP_DIR"

echo "Creating PostgreSQL backup..."

docker compose \
  -f "$(dirname "$0")/../compose.yaml" \
  exec -T postgres \
  pg_dump -U mnemetic -d mnemetic \
  > "$BACKUP_FILE"

echo "Backup complete:"
echo "$BACKUP_FILE"
