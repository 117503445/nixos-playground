FROM archlinux

LABEL maintainer="117503445"

# 初始化并填充 pacman 密钥环
RUN pacman-key --init && \
    pacman-key --populate && \
    pacman -Sy archlinux-keyring --noconfirm && \
    pacman -Su --noconfirm

# 安装所需软件包
RUN pacman -Syu zsh git openssh docker docker-compose docker-buildx base-devel go-task go zsh-autosuggestions zsh-syntax-highlighting --noconfirm

# 添加用户 builder，并安装 yay AUR 助手
RUN useradd -m -G wheel builder && \
    chown -R builder:builder /tmp && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    su - builder -c "cd /tmp && git clone https://aur.archlinux.org/yay.git yay && cd yay && makepkg -si --noconfirm" && \
    rm -rf /tmp/yay

RUN chsh -s /usr/bin/zsh

WORKDIR /workspace

COPY ./scripts/ci/entrypoint.sh /entrypoint

ENTRYPOINT [ "/entrypoint" ]