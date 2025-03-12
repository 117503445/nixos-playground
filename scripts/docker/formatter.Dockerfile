FROM registry.cn-hangzhou.aliyuncs.com/117503445-mirror/sync:linux.amd64.docker.io.library.alpine.latest

WORKDIR /workspace

RUN wget https://github.com/kamadorueda/alejandra/releases/download/3.1.0/alejandra-x86_64-unknown-linux-musl -O /usr/local/bin/alejandra && chmod +x /usr/local/bin/alejandra
# RUN wget https://gh-proxy.com/github.com/kamadorueda/alejandra/releases/download/3.1.0/alejandra-x86_64-unknown-linux-musl -O /usr/local/bin/alejandra && chmod +x /usr/local/bin/alejandra

ENTRYPOINT [ "alejandra", "." ]