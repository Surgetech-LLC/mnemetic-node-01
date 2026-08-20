# PostgreSQL Service

## Purpose

Containerized PostgreSQL service for Mnemetic Node 01 infrastructure experiments.

## Deployment

- PostgreSQL 18.4
- Docker Compose
- Named persistent volume
- Host access restricted to 127.0.0.1:5432
- Container health check using pg_isready
- Runtime password stored in gitignored .env

## Persistence Validation

A test table and row were created in the database.

The initial PostgreSQL container was then removed using:

docker compose down

The named Docker volume remained.

PostgreSQL was recreated using:

docker compose up -d

The new container received a different container ID, while the previously inserted database row remained present.

This validates that application state is stored independently of the disposable container lifecycle.

## Operational Commands

Start:

docker compose up -d

Status:

docker compose ps

Logs:

docker compose logs --tail=50 postgres

Stop and remove container/network while preserving data:

docker compose down

WARNING: Do not use `docker compose down -v` unless intentionally deleting the database volume.

## Backup Validation

A PostgreSQL backup workflow was implemented using pg_dump.

Backup process:

- Executes pg_dump inside the running PostgreSQL container
- Stores timestamped SQL backups locally
- Keeps backup credentials outside version control

Validation:

- Backup script successfully created a database dump
- Backup artifact generated:
  mnemetic-postgres-20260820_180903.sql
