
# Mnemetic Node 01 Monitoring

## Purpose

Track system and service health as infrastructure workloads increase.

## Current Metrics

Host:

- CPU utilization
- Memory usage
- Swap usage
- Disk capacity
- Network state
- Process health

Docker:

- Container status
- Container resource usage
- Logs
- Restart behavior

PostgreSQL:

- Container health check
- Database availability
- Backup status

## Current Deployment

Node exporter is deployed through:

    services/monitoring/node-exporter/compose.yaml

The pinned node-exporter endpoint is restricted to the local host:

    http://127.0.0.1:9100/metrics

Deploy or reconcile the service:

    ./scripts/deploy-monitoring.sh

Run the combined host and service report:

    ./scripts/health-report.sh

## Baseline (2026-08-20)

Memory:

- Total: 7.6 GiB
- Available: 4.6 GiB

Disk:

- Root filesystem: 912G
- Used: 14G

PostgreSQL:

- Memory: ~33 MiB
- CPU: near idle

## Future

Potential additions:

- Prometheus
- Grafana
- Automated alerts
