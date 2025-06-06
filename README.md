# nixos-playground

> 极易上手的 NixOS 游乐场

## 前言

### 为什么要用 NixOS

可参考 [NixOS 系列（一）：我为什么心动了](https://lantian.pub/article/modify-website/nixos-why.lantian/)，[NixOS 的优缺点](https://nixos-and-flakes.thiscute.world/zh/introduction/advantages-and-disadvantages)。对我个人而言，NixOS 的优点主要是可以使用声明式精准定义整个操作系统，并提供极强的可复现性。这样子，操作系统会具有极强的可维护性，可以轻松切换到每一个变更前的状态。有了这份保证，就可以在 Homelab 等高度灵活的部署环境中，随心所欲进行变更和尝试，而不用担心破坏了系统。

### NixOS Playground 是干什么的

NixOS Playground 是一个 NixOS 的游乐场，它提供了一套完整的 NixOS 起步配置。可以进行各种操作，比如生成系统镜像、运行虚拟机、更新已有的 NixOS 系统等。特别的是，NixOS Playground 本身不依赖于 Nix，只要在任意一个装有 Docker 的 Linux 发行版上都可以运行。甚至，在 CI 环境中也可以通过 Docker 生成 Nixos 配置所对应的镜像。

### 有哪些特别的配置技巧

NixOS Playground 的配置遵循了一系列最佳实践

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)，类似于 `go.sum` 和 `package.json`，使用 `flake.lock` 锁定外部依赖，保证可复现性
- GitOps，使用 Git 管理配置文件的每个版本
- [无状态操作系统](https://lantian.pub/article/modify-computer/nixos-impermanence.lantian/)，每次重启后，系统分区中的多余文件都会被删除，系统完全变为配置文件所对应的状态。只有用户指定的目录才会保留。
- [disko](https://github.com/nix-community/disko) 生成系统磁盘镜像。安装系统时会非常简单，只需要目标机器上运行 SSH，然后本地通过 SSH + dd 命令即可将本地的镜像文件刷写到目标机器的磁盘中。
- [alejandra](https://github.com/kamadorueda/alejandra) 格式化配置。当 Nix 配置出现语法错误时，Nix 的报错信息非常冗长。因此，在实际部署前先格式化，不仅保证了格式的一致性，还能快速定位语法错误。
- [nix-binary-cache](https://github.com/117503445/nix-binary-cache) 默认情况下，生成系统镜像时只会从上游源拉取 Nix 二进制包。我写了个缓存服务，能够指定是否通过 HTTP 代理从多个上游拉取二进制包，并提供给镜像构建时使用。

NixOS Playground 包含了几种场景下的 NixOS 配置。在我原有的 HomeLab 中，使用 OpenWRT 作为软路由操作系统，使用 PVE 作为服务器宿主操作系统，使用 ArchLinux 作为开发环境/生产环境。现在，一切都可以被 NixOS 替代，一切都可以被统一管理。每一条路由项、防火墙规则、QEMU 服务启动参数，都明明白白写在 NixOS 的配置文件中，而不是藏在 OpenWRT 和 PVE 的层层复杂抽象封装之下。

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

## 实现

在本节中，将详细介绍 Nix 配置和 Go 脚本的实现，帮助你进行个性化定制。

### 哲学

在我眼中，Docker Compose 是一个非常有力的运维工具。它使用声明式思想，使用结构化的 YAML 纯文本来描述容器的运行环境。维护者可以通过阅读 compose.yaml 快速了解容器的现有运行环境，也可以进行编辑实现新的运维变更。在使用 hash-tag 防止镜像意外改变后，Docker Compose 也具有较强的可复现性，不同时间部署不会影响部署结果，在不同机器上部署也不会影响部署结果。

但是 Docker 容器具有局限性，不能跑 systemd，不能用来运行完整的操作系统。因此，通过 NixOS，可以像维护 Docker Compose 一样维护操作系统。

### Nix

Nix 可以理解为图灵完备的 YAML，具有更强的表达能力，可以描述整个操作系统的运行环境。

在本 repo 中，入口点是 flake.nix。一个 flake 可以包含多个节点的配置定义。在 flake.nix 的 nodes 定义了各个节点的名称。比如 guest-test 节点，具体配置见 assets/flake/nodes/guest-test。

assets/flake/nodes/guest-test/configuration.nix 包含了系统配置

导入一些各个节点都有的配置，以及需要安装的软件

```nix
imports = [
  ../../lib/hardware-configuration.nix
  ../../lib/qemu-agent.nix

  ../../apps/sshd
  ../../apps/zsh
  ../../apps/docker
];
```

定义网络主机名和启动方式
```nix
  # 网络主机名
  networking.hostName = "guest-test";

  # UEFI 启动
  boot.loader.systemd-boot = {
    enable = true;
  };
```

定义网络配置

```nix
  networking = {
    useNetworkd = true;
    # 关闭 DHCP，手动配置 IP
    useDHCP = false;
    # 手动设置 DNS
    nameservers = ["223.5.5.5"];
    # 关闭 NixOS 自带的防火墙
    firewall.enable = false;
    # 禁用默认的网络接口命名规则，以允许自定义命名
    usePredictableInterfaceNames = false;
  };

  # 通过 systemd-network 配置网络 IP 和 DNS
  systemd.network.networks.eth0 = {
    networkConfig.DHCP = "yes";
    matchConfig.Name = "eth0";
  };
```

在 assets/flake/nodes/router-test/home.nix 定义了 home-manager 的配置

```nix
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../lib/home.nix
  ];
}
```

NixOS 常有 2 种软件安装方式。一种是 environment.systemPackages，如 assets/flake/apps/zellij/default.nix

```nix
environment.systemPackages = with pkgs; [zellij];
```

另一种是借助 home-manager 的 home.packages，参考 assets/flake/lib/home.nix。大部分软件我都是通过这种方式安装的。另外，home-manager 还配置了 shell 和 git。

### 磁盘镜像生成

在 assets/flake/lib/hardware-configuration.nix 中的 disko 定义了如何生成磁盘镜像。我个人喜欢分为 2 个区。前 128M 是 ESP(boot) 分区，剩下部分都是 nix 分区，用于储存实际数据。

- ESP 分区 使用 vfat 分区，Label 为 NixBoot，将挂载到 /boot
- nix 分区 使用 btrfs 分区，Label 为 NixOS，将挂载到 /nix

文件系统中

- `/` 使用 tmpfs，保证重启后可以自动丢弃多余文件
- `/boot` 挂载 NixBoot 分区
- `/nix` 挂载 NixOS 分区

此外，`/nix/persistent` 储存了 `/home` `/root` 等需要持久化的数据。启动后会将这些数据挂载到指定路径。

最后通过 nix build 生成 guest-test 的磁盘镜像

```sh
nix build --accept-flake-config --no-require-sigs --print-build-logs --show-trace .#build-guest-test
```

pkg/cli/build-image.go 包含了构建所有节点磁盘镜像的调用代码

参考 [制作小内存 VPS 的 DD 磁盘镜像](https://lantian.pub/article/modify-computer/nixos-low-ram-vps.lantian/)

### 磁盘镜像安装

通过上一步，生成了 guest-test.img。然后可以通过很方便的方式进行安装。

#### SSH + DD

首先在服务器 `123.45.67.89` 上，启用 SSH 服务

然后运行

```sh
cat guest-test.img | ssh root@123.45.67.89 "dd of=/dev/sda"
```

重启后，就完成系统安装了。

#### U 盘刷写

在 Windows 上可以使用 Refus 刷写到 U 盘。比如在路由器上，对储存的要求不高，因此可以直接在 u盘上跑操作系统。

#### 扩容

创建的磁盘镜像大小只有 2GB，dd 完成后的镜像不会占满 VPS 的硬盘空间，需要手动扩展分区。

先用 cfdisk，把剩余空间合并到 nix 分区

然后文件系统扩容

```sh
btrfs filesystem resize max /nix
```

### 增量部署

如果每次变更（增加、删除、修改）系统软件，都需要通过系统镜像进行刷写，是非常麻烦的。增量部署是更加方便、效率更加高的方式。参考 pkg/cli/deploy.go ，用户在 git repo 中完成 flake 的修改后，先通过 rsync 将 flake 同步至目标节点的 `/etc/nixos` 下，然后调用 `nixos-rebuild switch` 命令，更新配置。

### NixOS 替代 OpenWRT

在路由器上，我有组建虚拟局域网、分流等需求。以前我是用 OpenWRT，但是各种软件的版本较低，依赖环境奇怪，网络配置错综复杂，折腾起来非常麻烦。后来使用 NixOS 以后，具有以下优点

- 轻松支持最新版本软件，如 Tailscale，也可以使用满血 ebpf 进行高性能分流
- 轻松使用主流生态技术，比如 Systemd 和 nftable 等
- 统一使用 flake 管理，大幅提升可维护性

router-test 定义了一个简单的路由器系统。具有 2 个网口，在 LAN 口上启用 DHCP，并且通过 nftable 规则实现了 NAT。

在 NixOS-playground 中，router-test 有 2 张网卡，一张用于上网，还有一张用于和 guest-test 桥接。guest-test 作为局域网内的普通设备，借助 router-test 上网。

### NixOS 替代 PVE

最开始，我的 Homelab 主机中只运行 ArchLinux。后来我发现了一些问题

- 平时经常在 Arch 上操作，当遇到系统更新失败/磁盘爆满/网络失效等情况，无法正常进入系统后就无法通过网络恢复了，必须重新到物理机前键盘鼠标操作，很麻烦。
- 开发时的各种操作可能对生产环境产生影响。即使使用 docker，也不能保证所有情况的环境隔离

后面我在底层安装了 PVE 系统，创建了 2 个 Arch 虚拟机，分别作为开发环境和生产环境。

好处是

- 就算 Arch 崩了，也可以在 PVE 上看到 Arch