#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
POSTGRES_DIR="$REPO_ROOT/services/postgres"
POSTGRES_COMPOSE="$POSTGRES_DIR/compose.yaml"
POSTGRES_ENV="$POSTGRES_DIR/.env"
BACKUP_DIR="$POSTGRES_DIR/backup/archives"
MONITORING_COMPOSE="$REPO_ROOT/services/monitoring/node-exporter/compose.yaml"
METRICS_URL="http://127.0.0.1:9100/metrics"

FAILURES=0
WARNINGS=0
DOCKER_READY=0
COMPOSE_READY=0

section() {
    printf '\n== %s ==\n' "$1"
}

pass() {
    printf '[PASS] %s\n' "$1"
}

warn() {
    printf '[WARN] %s\n' "$1"
    WARNINGS=$((WARNINGS + 1))
}

fail() {
    printf '[FAIL] %s\n' "$1"
    FAILURES=$((FAILURES + 1))
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

compose_config_valid() {
    local compose_file=$1
    shift

    if docker compose "$@" -f "$compose_file" config --quiet >/dev/null 2>&1; then
        pass "Compose configuration is valid: $compose_file"
    else
        fail "Compose configuration is invalid: $compose_file"
    fi
}

compose_service_running() {
    local compose_file=$1
    local service=$2
    shift 2
    local running_services

    if ! running_services=$(docker compose "$@" -f "$compose_file" ps --status running --services 2>/dev/null); then
        fail "Could not query Compose service: $service"
        return
    fi

    if grep -Fxq "$service" <<< "$running_services"; then
        pass "Compose service is running: $service"
    else
        fail "Compose service is not running: $service"
    fi
}

node_exporter_ready() {
    curl --fail --silent --show-error --max-time 5 "$METRICS_URL" 2>/dev/null \
        | awk 'index($0, "node_exporter_build_info{") == 1 { found = 1 }
            END { exit(found ? 0 : 1) }'
}

if (( $# != 0 )); then
    printf 'Usage: %s\n' "$0" >&2
    exit 2
fi

section "Mnemetic Node 01 health report"
printf 'Generated: %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
printf 'Host: %s\n' "$(hostname 2>/dev/null || printf 'unknown')"
printf 'Repository: %s\n' "$REPO_ROOT"

section "Host"
if uptime_output=$(uptime 2>/dev/null); then
    printf 'Uptime/load: %s\n' "$uptime_output"
else
    warn "Could not read host uptime"
fi

if command_exists free && memory_output=$(free -h 2>/dev/null); then
    printf 'Memory:\n'
    sed 's/^/  /' <<< "$memory_output"
else
    warn "Memory usage could not be reported"
fi

if command_exists df && filesystem_output=$(df -h / 2>/dev/null); then
    printf 'Root filesystem:\n'
    sed 's/^/  /' <<< "$filesystem_output"
else
    warn "Root filesystem usage could not be reported"
fi

section "Docker"
if ! command_exists docker; then
    fail "Docker CLI is unavailable"
else
    if docker_version=$(docker --version 2>/dev/null); then
        pass "$docker_version"
    else
        fail "Docker CLI version check failed"
    fi

    if compose_version=$(docker compose version 2>/dev/null); then
        pass "$compose_version"
        COMPOSE_READY=1
    else
        fail "Docker Compose plugin is unavailable"
    fi

    if docker_server_version=$(docker info --format '{{.ServerVersion}}' 2>/dev/null); then
        pass "Docker daemon is reachable (server $docker_server_version)"
        DOCKER_READY=1
    else
        fail "Docker daemon is not reachable by the current user"
    fi
fi

section "PostgreSQL"
if [[ -r "$POSTGRES_ENV" ]]; then
    pass "PostgreSQL environment file is present and readable"
else
    fail "PostgreSQL environment file is missing or unreadable: $POSTGRES_ENV"
fi

if (( COMPOSE_READY == 1 )) && [[ -r "$POSTGRES_ENV" ]]; then
    compose_config_valid "$POSTGRES_COMPOSE" --env-file "$POSTGRES_ENV"
else
    warn "PostgreSQL Compose validation was skipped"
fi

if (( DOCKER_READY == 1 && COMPOSE_READY == 1 )) && [[ -r "$POSTGRES_ENV" ]]; then
    compose_service_running "$POSTGRES_COMPOSE" postgres --env-file "$POSTGRES_ENV"

    if docker compose --env-file "$POSTGRES_ENV" -f "$POSTGRES_COMPOSE" \
        exec -T postgres pg_isready -U mnemetic -d mnemetic >/dev/null 2>&1; then
        pass "PostgreSQL accepts readiness checks"
    else
        fail "PostgreSQL readiness check failed"
    fi
elif (exec 3<>/dev/tcp/127.0.0.1/5432) 2>/dev/null; then
    pass "PostgreSQL TCP endpoint is reachable at 127.0.0.1:5432"
    warn "Container state and database readiness could not be verified without Docker access"
else
    fail "PostgreSQL TCP endpoint is unavailable at 127.0.0.1:5432"
fi

if [[ -d "$BACKUP_DIR" ]]; then
    latest_backup=$(find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name 'mnemetic-postgres-*.sql' -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr | sed -n '1{s/^[^ ]* //;p;}') || latest_backup=""

    if [[ -n "$latest_backup" && -s "$latest_backup" ]]; then
        if backup_metadata=$(stat -c '%n (%s bytes; modified %y)' "$latest_backup" 2>/dev/null); then
            pass "Latest PostgreSQL backup: $backup_metadata"
        else
            warn "Latest PostgreSQL backup metadata could not be read"
        fi
    else
        warn "No nonempty PostgreSQL backup archive was found"
    fi
else
    warn "PostgreSQL backup archive directory does not exist yet"
fi

section "Node exporter"
if (( COMPOSE_READY == 1 )); then
    compose_config_valid "$MONITORING_COMPOSE"
else
    warn "Node-exporter Compose validation was skipped"
fi

if (( DOCKER_READY == 1 && COMPOSE_READY == 1 )); then
    compose_service_running "$MONITORING_COMPOSE" node-exporter
fi

if ! command_exists curl || ! command_exists awk; then
    fail "curl and awk are required to validate node-exporter metrics"
elif node_exporter_ready; then
    pass "Node-exporter metrics endpoint is valid: $METRICS_URL"
else
    fail "Node-exporter metrics endpoint is unavailable or invalid: $METRICS_URL"
fi

section "Summary"
printf 'Failures: %d\n' "$FAILURES"
printf 'Warnings: %d\n' "$WARNINGS"

if (( FAILURES > 0 )); then
    printf 'Overall status: UNHEALTHY\n'
    exit 1
fi

printf 'Overall status: HEALTHY\n'
