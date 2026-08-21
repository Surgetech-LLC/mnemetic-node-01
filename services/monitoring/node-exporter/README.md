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
