FROM registry.cn-hangzhou.aliyuncs.com/117503445-mirror/dev-base

RUN pacman -Sy --noconfirm go-task docker qemu dhclient rsync kubectl kustomize
RUN su - builder -c "yay -Sy --noconfirm novnc"

RUN go env -w GOPROXY=https://goproxy.cn,direct
RUN go install github.com/117503445/nix-binary-cache@master
RUN go install github.com/mattn/goreman@latest
ENV PATH $PATH:/root/go/bin
RUN curl -L https://github.com/regclient/regclient/releases/latest/download/regctl-linux-amd64 -o /usr/local/bin/regctl && chmod +x /usr/local/bin/regctl
# RUN curl -L https://gh-proxy.com/github.com/regclient/regclient/releases/latest/download/regctl-linux-amd64 -o /usr/local/bin/regctl && chmod +x /usr/local/bin/regctl
ENTRYPOINT [ "goreman", "-basedir", "./scripts", "start"] 