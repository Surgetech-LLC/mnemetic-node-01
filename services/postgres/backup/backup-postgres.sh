#!/bin/bash

set -Eeuo pipefail

umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
POSTGRES_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$POSTGRES_DIR/compose.yaml"
ENV_FILE="$POSTGRES_DIR/.env"
BACKUP_DIR="$SCRIPT_DIR/archives"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILE="$BACKUP_DIR/mnemetic-postgres-$TIMESTAMP.sql"
TEMP_FILE=""

die() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

cleanup() {
    if [[ -n "$TEMP_FILE" && -e "$TEMP_FILE" ]]; then
        rm -f -- "$TEMP_FILE"
    fi
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if (( $# != 0 )); then
    die "Usage: $0"
fi

command -v docker >/dev/null 2>&1 || die "Docker CLI is required"
docker compose version >/dev/null 2>&1 || die "Docker Compose plugin is required"
[[ -r "$ENV_FILE" ]] || die "Missing or unreadable environment file: $ENV_FILE"

mkdir -p "$BACKUP_DIR"
[[ -d "$BACKUP_DIR" && -w "$BACKUP_DIR" ]] \
    || die "Backup directory is not writable: $BACKUP_DIR"

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config --quiet

if ! docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" \
    ps --status running --services | grep -Fxq postgres; then
    die "PostgreSQL Compose service is not running"
fi

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" \
    exec -T postgres pg_isready -U mnemetic -d mnemetic >/dev/null \
    || die "PostgreSQL readiness check failed"

[[ ! -e "$BACKUP_FILE" ]] \
    || die "Refusing to overwrite existing backup: $BACKUP_FILE"

TEMP_FILE="$(mktemp "$BACKUP_DIR/.mnemetic-postgres-$TIMESTAMP.XXXXXX")"

printf 'Creating PostgreSQL backup...\n'

if ! docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" \
    exec -T postgres pg_dump -U mnemetic -d mnemetic > "$TEMP_FILE"; then
    die "pg_dump failed; incomplete backup removed"
fi

[[ -s "$TEMP_FILE" ]] || die "pg_dump produced an empty backup"
chmod 600 "$TEMP_FILE"

if ! ln -- "$TEMP_FILE" "$BACKUP_FILE"; then
    die "Refusing to overwrite backup created by another process: $BACKUP_FILE"
fi

rm -f -- "$TEMP_FILE"
TEMP_FILE=""
trap - EXIT HUP INT TERM

printf 'Backup complete:\n%s\n' "$BACKUP_FILE"
