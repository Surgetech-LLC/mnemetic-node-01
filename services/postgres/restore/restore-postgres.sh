#!/bin/bash

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: ./restore-postgres.sh <backup-file>"
    exit 1
fi

BACKUP_FILE="$1"

echo "Restoring PostgreSQL backup..."

docker compose \
  -f "$(dirname "$0")/../compose.yaml" \
  exec -T postgres \
  psql -U mnemetic -d mnemetic \
  < "$BACKUP_FILE"

echo "Restore complete."
