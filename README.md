# nixos-playground

> 极易上手的 NixOS 游乐场

## 前言

### 为什么要用 NixOS

可参考 [NixOS 系列（一）：我为什么心动了](https://lantian.pub/article/modify-website/nixos-why.lantian/)，[NixOS 的优缺点](https://nixos-and-flakes.thiscute.world/zh/introduction/advantages-and-disadvantages)。对我个人而言，NixOS 的优点主要是可以使用声明式精准定义整个操作系统，并提供极强的可复现性。这样子，操作系统会具有极强的可维护性，可以轻松切换到每一个变更前的状态。有了这份保证，就可以在 Homelab 等高度灵活的部署环境中，随心所欲进行变更和尝试，而不用担心破坏了系统。

### NixOS Playground 是干什么的

NixOS Playground 是一个 NixOS 的游乐场，它提供了一套完整的 NixOS 起步配置。可以进行各种操作，比如生成系统镜像、运行虚拟机、更新已有的 NixOS 系统等。特别的是，NixOS Playground 本身不依赖于 Nix，只要在任意一个装有 Docker 的 Linux 发行版上都可以运行。甚至，在 CI 环境中也可以通过 Docker 生成 Nixos 配置所生成的镜像。

### 有哪些特别的配置技巧

NixOS Playground 的配置遵循了一系列最佳实践

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)，类似于 `go.sum` 和 `package.json`，使用 `flake.lock` 锁定外部依赖，保证可复现性
- GitOps，使用 Git 管理配置文件的每个版本
- [无状态操作系统](https://lantian.pub/article/modify-computer/nixos-impermanence.lantian/)，每次重启后，系统分区中的多余文件都会被删除，系统完全变为配置文件所对应的状态。只有用户指定的目录才会保留。
- [disko](https://github.com/nix-community/disko) 生成系统磁盘镜像。安装系统时会非常简单，只需要目标机器上运行 SSH，然后本地通过 SSH + dd 命令即可将本地的镜像文件刷写到目标机器的磁盘中。
- [alejandra](https://github.com/kamadorueda/alejandra) 格式化配置。当 Nix 配置出现语法错误时，Nix 的报错信息非常冗长。因此，在实际部署前先格式化，不仅保证了格式的一致性，还能快速定位语法错误。
- [nix-binary-cache](https://github.com/117503445/nix-binary-cache) 默认情况下，生成系统镜像时只会从上游源拉取 Nix 二进制包。我写了个缓存服务，能够指定是否通过 HTTP 代理从多个上游拉取二进制包，并提供给镜像构建时使用。

包含了几种场景下的 NixOS 配置。在我原有的 HomeLab 中，使用 OpenWRT 作为软路由操作系统，使用 PVE 作为服务器宿主操作系统，使用 ArchLinux 作为开发环境/生产环境所用。现在，一切都可以被 NixOS 替代，一切都可以被统一管理。每一条路由项、防火墙规则、QEMU 服务启动参数，都明明白白写在 NixOS 的配置文件中，而不是藏在 OpenWRT 和 PVE 的层层复杂抽象之下。

- 基础款，配置了 Zsh 和 Docker，适合用于开发环境，或者以此为基础进行构建
- NAT，直接用 NixOS 取代 OpenWRT
- QEMU，直接用 NixOS 取代 PVE

此外，还有一些技巧

本游乐场运行在 Docker 环境中，但是仍需要通过容器来使用 alejandra 和 Nix，因此就使用了 Docker in Docker。

为了在 Docker 环境中运行虚拟机，使用了 QEMU in Docker。期间，还会对 Docker 环境的网络进行配置，以实现虚拟机的桥接上网。

## 快速开始

### 虚拟机运行硬盘镜像

首先确保有一个安装 Docker 的 Linux 发行版

还需要开启嵌套虚拟化。HyperV 默认是不开启嵌套虚拟化的，请参考 [enable-nested-virtualization](https://learn.microsoft.com/zh-cn/virtualization/hyper-v-on-windows/user-guide/enable-nested-virtualization) 开启嵌套虚拟化。

```sh
# 检查是否已开启嵌套虚拟化
cat /sys/module/kvm_intel/parameters/nested
cat /sys/module/kvm_amd/parameters/nested
```

准备 Docker Compose 声明文件

```yaml
# compose.yaml
services:
  runner:
    image: 117503445/nixos-playground
    # restart: unless-stopped
    devices:
      - /dev/kvm
      - /dev/net/tun
    privileged: true
    ports:
      - 6080:6080
    volumes:
      - data:/workspace/data
volumes:
  data:
```

启动

```sh
docker compose up
```

启动容器后会自动下载磁盘镜像。也可以提前下载磁盘镜像 <https://github.com/117503445/nixos-playground/releases/latest/download/nixos-test.img>，然后挂载为容器内的 /workspace/data/vm.img

然后在 6080 端口即可访问虚拟机，用户名 root，密码 1

### 搭建本地 playground 环境

为后面的步骤提供基础

clone 本项目

```sh
git clone https://github.com/117503445/nixos-playground.git
cd nixos-playground
```

启动开发镜像

```sh
docker compose up -d
```

### 构建磁盘镜像

```sh
docker compose exec dev go-task build-img
```

预期在 `data/img` 目录下生成 `nixos-test.img` `guest-test.img` `router-test.img`

### 运行虚拟机

```sh
docker compose exec dev go-task run-vm
```

可以在容器内的 6080 6081 6082 端口通过 VNC 访问虚拟机了。如果需要在容器外访问，可以修改 compose.yaml 文件，将 6080 6081 6082 端口映射到宿主机的任意端口上。

### 部署新配置

当需要对系统进行变更时，需要修改 flake 文件。可以在修改后，生成磁盘镜像，然后重新刷写，但是这太麻烦了。

运行一下命令，将更改后的配置应用于正在运行的 nixos-test 虚拟机，速度更快

```sh
docker compose exec dev go-task deploy
```

