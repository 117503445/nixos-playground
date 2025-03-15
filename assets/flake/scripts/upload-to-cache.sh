#!/usr/bin/env sh

# https://nix.dev/manual/nix/2.19/advanced-topics/post-build-hook
set -eu

echo "Uploading to cache, OUT_PATHS: $OUT_PATHS, NIX_CACHE_URL: $NIX_CACHE_URL"

# 如果 $NIX_CACHE_URL 中包含 "ustc" 或 "cache.nixos.org"，则跳过上传
if echo "$NIX_CACHE_URL" | grep -qE "ustc|cache\.nixos\.org"; then
    echo "Skip uploading to cache"
    exit 0
fi

# TODO: very slow, CPU bound, https://discourse.nixos.org/t/speed-up-nix-copy/15884
nix copy --no-check-sigs --to $NIX_CACHE_URL $OUT_PATHS || true