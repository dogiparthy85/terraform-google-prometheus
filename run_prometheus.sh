#!/usr/bin/env bash

# Remove the container if already present.
docker rm -f prometheus

# Run prometheus.
docker run \
  -d \
  --rm \
  --network prometheus \
  --name prometheus \
  -p 9090:9090 \
  --log-driver journald \
  -v prometheus-data:/prometheus \
  -v /etc/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --log.level=${log_level}
