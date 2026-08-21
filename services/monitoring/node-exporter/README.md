# Node Exporter

## Purpose

Provides system metrics for Mnemetic Node 01.

## Deployment

- Containerized using Docker Compose
- Image: prom/node-exporter:v1.8.2
- Local metrics endpoint: 127.0.0.1:9100

## Exposed Metrics

Provides visibility into:

- CPU
- Memory
- Disk
- Filesystem
- Network interfaces
- System processes

## Validation

Verified that the metrics endpoint responds successfully:

curl http://127.0.0.1:9100/metrics

## Operations

From the repository root, deploy or reconcile node exporter with:

    ./scripts/deploy-monitoring.sh

The helper validates the existing Compose file, runs docker compose up -d, and
waits for node-exporter build metrics from the local endpoint. It is safe to run
repeatedly and does not tear down containers, networks, or volumes.

Status:

    docker compose -f services/monitoring/node-exporter/compose.yaml ps

Recent logs:

    docker compose -f services/monitoring/node-exporter/compose.yaml logs --tail=50 node-exporter

Combined host and service health:

    ./scripts/health-report.sh

See [../../../docs/operations.md](../../../docs/operations.md) for full usage
and troubleshooting guidance.
