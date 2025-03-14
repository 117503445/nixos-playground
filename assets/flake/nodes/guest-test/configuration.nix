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
    # ../../apps/code-server
    # ../../apps/docker
    # ../../apps/frpc
  ];

  # 网络主机名
  networking.hostName = "guest-test";

  # MBR 启动
  # boot.loader.grub = {
  #   enable = true;
  #   default = "saved";
  #   devices = ["/dev/vda"];
  # };
  # UEFI 启动
  boot.loader.systemd-boot = {
    enable = true;
  };

  networking = {
    # 关闭 DHCP，手动配置 IP
    # useDHCP = false;
    # 手动设置 DNS
    nameservers = ["223.5.5.5"];
    # 手动设置默认网关
    # defaultGateway = {
    #   address = "172.19.0.1";
    #   interface = "eth0";
    # };
    # 关闭 NixOS 自带的防火墙
    firewall.enable = false;
    # 禁用默认的网络接口命名规则，以允许自定义命名
    usePredictableInterfaceNames = false;
  };

  # 通过 systemd-network 配置网络 IP 和 DNS
  systemd.network.networks.eth0 = {
    # address = ["172.19.0.3/16"];
    # gateway = ["172.19.0.1"];
    networkConfig.DHCP = "yes";
    matchConfig.Name = "eth0";
  };

  # 首次安装系统时 NixOS 的最新版本，用于在大版本升级时避免发生向前不兼容的情况
  system.stateVersion = "24.11";
}
