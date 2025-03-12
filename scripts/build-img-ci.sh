#!/usr/bin/env sh

set -e

docker build -t 117503445/nixos-playground-ci -f ./scripts/ci/Dockerfile .
docker run --rm -v $(pwd):/workspace -v docker:/var/lib/docker --privileged --cap-add=NET_ADMIN --device /dev/net/tun 117503445/nixos-playground-ci