ARG BASE_IMAGE

FROM ${BASE_IMAGE}
# FROM registry.cn-hangzhou.aliyuncs.com/117503445-mirror/sync:linux.amd64.docker.io.nixos.nix.latest

RUN echo >> /etc/nix/nix.conf "experimental-features = nix-command flakes"

ENTRYPOINT [ "/entrypoint" ]

WORKDIR /workspace