#!/bin/sh

echo "Building image."

docker \
  --host=unix:///var/run/dockerServices.sock build \
  --tag=wpcloud/docker-storage:1.0.0 \
  $(readlink -f $(pwd))
