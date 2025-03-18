#!/usr/bin/env sh

set -e

cp ./assets/flake/nodes/nixos-test/net.toml.example ./assets/flake/nodes/nixos-test/net.toml

docker build -t 117503445/nixos-playground-ci -f ./scripts/ci/Dockerfile .
docker run --rm -v $(pwd):/workspace -v docker:/var/lib/docker --privileged --cap-add=NET_ADMIN --device /dev/net/tun 117503445/nixos-playground-ci