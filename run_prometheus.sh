#!/usr/bin/env sh

# Remove the container if there is one already.
docker rm -f prometheus

# Run the container.
docker run \
  -d \
  --rm \
  --name prometheus \
  --log-driver journald \
  -v prometheus-data:/prometheus \
  -v /etc/prometheus.yaml:/etc/prometheus/prometheus.yaml \
  ${image}
