#!/usr/bin/env sh

# https://nix.dev/manual/nix/2.19/advanced-topics/post-build-hook
set -eu

echo "Uploading to cache, paths: $OUT_PATHS"
echo "NIX_CACHE_URL: $NIX_CACHE_URL"

# if "ustc" in $NIX_CACHE_URL, skip
if echo "$NIX_CACHE_URL" | grep -q "ustc"; then
    echo "Skip uploading to cache"
    exit 0
fi

# TODO: very slow, CPU bound, https://discourse.nixos.org/t/speed-up-nix-copy/15884
nix copy --no-check-sigs --to $NIX_CACHE_URL $OUT_PATHS || true