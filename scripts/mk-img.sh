#!/usr/bin/env sh

# TODO: rewrite in go

set -evx

if [ -z "$NAME" ]; then
  echo "Please set NAME environment variable"
  exit 1
fi

if [ -z "$NIX_CACHE_URL" ]; then
  echo "Please set NIX_CACHE_URL environment variable"
  exit 1
fi

# SUBSTITUTERS_LINE="substituters = $NIX_CACHE_URL"

# 检查文件中是否包含 substituters 行，并进行相应操作
# if grep -q "^substituters =" /etc/nix/nix.conf; then
#     # 如果找到 substituters 行，则使用 sed 命令替换它
#     sed -i "s|^substituters =.*|$SUBSTITUTERS_LINE|" /etc/nix/nix.conf
# else
#     # 如果没有找到，则将新行追加到文件末尾
#     echo "$SUBSTITUTERS_LINE" | tee -a /etc/nix/nix.conf > /dev/null
# fi

cat /etc/nix/nix.conf
# 1024MB = 1024 * 1024 * 1024 bytes = 1073741824 bytes

echo "Name: $NAME, NIX_CACHE_URL: $NIX_CACHE_URL, HTTP_PROXY: $HTTP_PROXY"
#nix build --help
NIX_CONFIG="substituters = $NIX_CACHE_URL" NIX_CACHE_URL=$NIX_CACHE_URL https_proxy=$HTTP_PROXY nix build --accept-flake-config --no-require-sigs --print-build-logs --show-trace .#build-$NAME 
# --substituters=$NIX_CACHE_URL --trusted-substituters=$NIX_CACHE_URL
mv result/main.raw /data/$NAME.img
rm result