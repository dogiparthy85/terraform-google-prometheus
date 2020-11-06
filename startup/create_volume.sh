#!/usr/bin/env bash

docker volume create -o type=xfs -o device=/dev/disk/by-id/google-${name}-data-part1 prometheus-data
