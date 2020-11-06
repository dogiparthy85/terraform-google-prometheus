#!/usr/bin/env bash

disk="/dev/disk/by-id/google-${name}-data"
partition="$disk-part1"

# Create the partition.
if [ ! -b "$partition" ]; then
  echo ";" | sfdisk "$disk"
fi

sleep 3

# Always run this. It won't overwrite anything.
mkfs.xfs "$partition"
