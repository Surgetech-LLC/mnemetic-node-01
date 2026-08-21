# Mnemetic Node 01 Operations Toolkit

## Purpose

This toolkit provides small, repeatable commands for inspecting and operating
the existing PostgreSQL and node-exporter deployments.

It does not change the service architecture. Each service continues to use its
own Docker Compose file under services/.

## Prerequisites

- Bash
- Docker Engine
- Docker Compose plugin
- curl
- awk
- A current user that can access the Docker daemon
- services/postgres/.env containing POSTGRES_PASSWORD

The scripts do not invoke sudo. If Docker reports a socket permission error,
fix the user session or Docker access outside these scripts, then run the
command again.

All commands below are shown from the repository root. The scripts resolve
their own paths, so they can also be invoked by absolute path from another
working directory.

## Health report

Run:

    ./scripts/health-report.sh

The report checks:

- host uptime and load
- memory usage
- root filesystem capacity
- Docker CLI, Compose plugin, and daemon access
- both Compose configurations
- PostgreSQL service state and pg_isready response
- the most recent local PostgreSQL backup
- node-exporter service state and metrics endpoint

The report is read-only. It never starts or stops services, reads database
contents, or prints the PostgreSQL environment file.

Exit status is 0 when no checks fail and 1 when one or more checks fail.
Warnings are included in the report but do not by themselves make the result
unhealthy.

When Docker access is unavailable, the report still probes the loopback
PostgreSQL port and node-exporter HTTP endpoint. Those endpoint checks do not
replace container-state or database-readiness verification, so the missing
Docker access is still reported as a failure.

## PostgreSQL backup

Run the repository-level wrapper:

    ./scripts/backup-postgres.sh

The wrapper delegates to:

    services/postgres/backup/backup-postgres.sh

Before dumping, the service script validates the Compose configuration,
confirms that the PostgreSQL service is running, and runs pg_isready. The dump
is written to a restrictive temporary file and published under its final name
only after pg_dump succeeds and produces nonempty output.

Backups are stored in:

    services/postgres/backup/archives/

Final names retain the existing pattern:

    mnemetic-postgres-YYYYMMDD_HHMMSS.sql

Backup files are created with owner-only permissions. The script refuses to
overwrite an existing final file. A failed or interrupted dump removes only
its own temporary file.

Backups may contain sensitive application data. The archive directory is
ignored by Git, but backups should still be copied to appropriately protected
storage when they are needed for recovery.

The toolkit does not delete or rotate backups. Retention remains an explicit
operator decision.

For restoration and the validated recovery procedure, see:

- services/postgres/README.md
- services/postgres/recovery-test.md

## Monitoring deployment

Deploy or reconcile the existing node-exporter service:

    ./scripts/deploy-monitoring.sh

The helper:

1. Confirms Docker, Compose, curl, and Docker daemon access.
2. Validates services/monitoring/node-exporter/compose.yaml.
3. Runs docker compose up -d against that file.
4. Waits up to approximately 30 seconds for node-exporter build metrics.
5. Prints the resulting Compose status.

The command is safe to run repeatedly. Docker Compose reconciles the same
pinned service definition, and the helper does not use down, volume removal,
or forced recreation.

Metrics remain restricted to the local host:

    curl http://127.0.0.1:9100/metrics

## Safety and repeatability

The toolkit follows these operating rules:

- no sudo escalation
- no secret output
- no database-volume operations
- no container or network teardown
- no automatic backup deletion
- atomic publication of successful backups
- bounded readiness waits
- nonzero exit status on operational failure

The health report is idempotent because it is read-only. The deployment helper
is idempotent because it repeatedly reconciles the same Compose service. The
backup command is intentionally additive: every successful invocation creates
a new recovery artifact rather than replacing an existing one.

## Troubleshooting

Check Compose syntax without changing a deployment:

    docker compose -f services/postgres/compose.yaml config --quiet
    docker compose -f services/monitoring/node-exporter/compose.yaml config --quiet

Check service status:

    docker compose -f services/postgres/compose.yaml ps
    docker compose -f services/monitoring/node-exporter/compose.yaml ps

Inspect recent logs:

    docker compose -f services/postgres/compose.yaml logs --tail=50 postgres
    docker compose -f services/monitoring/node-exporter/compose.yaml logs --tail=50 node-exporter

The operational scripts deliberately stop when Docker daemon access is not
available. They do not attempt to bypass that boundary with sudo.
