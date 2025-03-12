#!/usr/bin/env sh

set -e

mkdir -p /workspace/data/logs

nohup dockerd > /workspace/data/logs/dockerd.log 2>&1 &

go run . build-img --nix-cache-disable --nix-base-image nixos/nix