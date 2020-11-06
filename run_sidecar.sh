#!/usr/bin/env bash

docker rm -f sidecar

# Run the sidecar
docker run \
  -d \
  --rm \
  --name sidecar \
  --log-driver journald \
  --network prometheus \
  -v prometheus-data:/prometheus \
  -v /etc/prometheus.yml:/etc/prometheus/prometheus.yml \
  gcr.io/stackdriver-prometheus/stackdriver-prometheus-sidecar:0.8.0 \
    --stackdriver.project-id=${project} \
    --stackdriver.metrics-prefix="custom.googleapis.com" \
    --config-file=/etc/prometheus/prometheus.yml \
    --prometheus.wal-directory=/prometheus/wal \
    --log.level=${log_level} \
    --prometheus.api-address=http://prometheus:9090
