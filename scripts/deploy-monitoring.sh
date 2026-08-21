#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/services/monitoring/node-exporter/compose.yaml"
METRICS_URL="http://127.0.0.1:9100/metrics"
MAX_ATTEMPTS=10

die() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

node_exporter_ready() {
    curl --fail --silent --show-error --max-time 2 "$METRICS_URL" 2>/dev/null \
        | awk 'index($0, "node_exporter_build_info{") == 1 { found = 1 }
            END { exit(found ? 0 : 1) }'
}

if (( $# != 0 )); then
    die "Usage: $0"
fi

command -v docker >/dev/null 2>&1 || die "Docker CLI is required"
docker compose version >/dev/null 2>&1 || die "Docker Compose plugin is required"
command -v curl >/dev/null 2>&1 || die "curl is required"
command -v awk >/dev/null 2>&1 || die "awk is required"

docker info >/dev/null 2>&1 \
    || die "Docker daemon is not reachable by the current user"

printf 'Validating node-exporter Compose configuration...\n'
docker compose -f "$COMPOSE_FILE" config --quiet

printf 'Deploying node exporter...\n'
docker compose -f "$COMPOSE_FILE" up -d

printf 'Waiting for %s...\n' "$METRICS_URL"
for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
    if node_exporter_ready; then
        printf 'Node exporter is ready.\n'
        docker compose -f "$COMPOSE_FILE" ps
        exit 0
    fi

    if (( attempt < MAX_ATTEMPTS )); then
        sleep 1
    fi
done

docker compose -f "$COMPOSE_FILE" ps >&2 || true
die "Node-exporter metrics endpoint did not become ready"
