# Mnemetic Node 01xxc

First SURGETECH/Mnemetic infrastructure node.

## Hardware

- Lenovo IdeaCentre 510A-15ICB
- Intel Core i5-8400
- 8GB DDR4 RAM (upgrade planned)
- 1TB HDD (NVMe upgrade planned)
- Intel UHD 630
- Linux Mint 22.1 XFCE

## Current Capabilities

- Native Linux workstation
- ChatGPT Linux app
- Codex environment
- Git
- System diagnostics
- Docker Compose services for PostgreSQL and node exporter
- Repeatable health, backup, and monitoring deployment operations

## Operations

The operations toolkit is documented in [docs/operations.md](docs/operations.md).

Primary commands:

    ./scripts/health-report.sh
    ./scripts/backup-postgres.sh
    ./scripts/deploy-monitoring.sh

## Roadmap

- NVMe storage upgrade
- RAM upgrade to 16GB
- Docker services
- Infrastructure automation
- Mnemetic experiments
