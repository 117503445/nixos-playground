{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../lib/hardware-configuration.nix
    ../../lib/qemu-agent.nix

    ../../apps/sshd
    ../../apps/zsh
    ../../apps/incus
  ];

  # 网络主机名
  networking.hostName = "incus-test";

  # UEFI 启动
  boot.loader.systemd-boot = {
    enable = true;
  };

  networking = {
    # 关闭 DHCP，手动配置 IP
    useDHCP = false;
    # 手动设置 DNS
    nameservers = ["223.5.5.5"];
    # 手动设置默认网关
    defaultGateway = {
      address = "172.19.0.1"; # TODO
      interface = "br0";
    };
    # 关闭 NixOS 自带的防火墙
    firewall.enable = false;
    # 禁用默认的网络接口命名规则，以允许自定义命名
    usePredictableInterfaceNames = false;
  };

  # 通过 systemd-network 配置网络 IP 和 DNS
  # systemd.network.networks.eth0 = {
  #   address = [(builtins.fromTOML (builtins.readFile ./net.toml)).address];
  #   gateway = [(builtins.fromTOML (builtins.readFile ./net.toml)).gateway];
  #   matchConfig.Name = "eth0";
  # };

  systemd.network = {
    enable = true;

    netdevs."10-br0" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br0";
        # 可选：启用 STP（生成树协议），防止环路
        # Bridge.STP = true;
      };
    };

    # 不需要 links（因为你用 eth0，且已禁用 predictable naming）

    networks = {
      # 1. 创建网桥 br0，并配置原 eth0 的 IP
      "10-br0" = {
        matchConfig.Name = "br0";
        # bridgeConfig.STP = false; # 可选，单网卡可关闭 STP
        address = [(builtins.fromTOML (builtins.readFile ./net.toml)).address];
        gateway = [(builtins.fromTOML (builtins.readFile ./net.toml)).gateway];
      };

      # 2. 将 eth0 加入网桥（不配 IP！）
      "20-eth0" = {
        matchConfig.Name = "eth0";
        networkConfig.Bridge = "br0"; # 关键：加入 br0
        networkConfig.DHCP = "no";
        # 不要设置 address/gateway！
      };
    };
  };

  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;

  disko.devices.disk.main.imageSize = lib.mkForce "10G";

  # 首次安装系统时 NixOS 的最新版本，用于在大版本升级时避免发生向前不兼容的情况
  system.stateVersion = "24.11";
}
