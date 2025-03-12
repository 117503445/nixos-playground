#!/usr/bin/env sh

set -evx

if [ -z "$NAME" ]; then
  echo "Please set NAME environment variable"
  exit 1
fi

if [ -z "$NIX_CACHE_URL" ]; then
  echo "Please set NIX_CACHE_URL environment variable"
  exit 1
fi

cat << EOF >> /etc/nix/nix.conf
substituters = $NIX_CACHE_URL
EOF
# trusted-substituters = $NIX_CACHE_URL

cat /etc/nix/nix.conf
# 1024MB = 1024 * 1024 * 1024 bytes = 1073741824 bytes

echo "Name: $NAME, NIX_CACHE_URL: $NIX_CACHE_URL, HTTP_PROXY: $HTTP_PROXY"
#nix build --help
NIX_CACHE_URL=$NIX_CACHE_URL https_proxy=$HTTP_PROXY nix build --accept-flake-config --no-require-sigs --print-build-logs --show-trace  .#build-$NAME
# --substituters=$NIX_CACHE_URL --trusted-substituters=$NIX_CACHE_URL
mv result/main.raw /data/$NAME.img
rm result