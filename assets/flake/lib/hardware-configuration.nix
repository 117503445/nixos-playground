{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  # boot.kernelParams = [
  #   # 关闭内核的操作审计功能
  #   "audit=0"
  # ];

  # 我用的 Initrd 配置，开启 ZSTD 压缩和基于 systemd 的第一阶段启动
  boot.initrd = {
    compressor = "zstd";
    compressorArgs = ["-19" "-T0"];
    systemd.enable = true;
  };
  time.timeZone = "Asia/Shanghai";
  users.mutableUsers = false;
  # Root 用户的密码和 SSH 密钥。如果网络配置有误，可以用此处的密码在控制台上登录进去手动调整网络配置。
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDYV5Hoaed4dQSmRoZrX+x6p+r16uBHVgv1Zkl8DOMRD 117503445-gen3" # content of authorized_keys file
    ];
    initialPassword = "1";
  };
  # 使用 systemd-networkd 管理网络
  systemd.network.enable = true;
  services.resolved.enable = false;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  disko = {
    # 不要让 Disko 直接管理 NixOS 的 fileSystems.* 配置。
    # 原因是 Disko 默认通过 GPT 分区表的分区名挂载分区，但分区名很容易被 fdisk 等工具覆盖掉。
    # 导致一旦新配置部署失败，磁盘镜像自带的旧配置也无法正常启动。
    enableConfig = false;

    memSize = 8000; # in MiB

    devices = {
      # 定义一个磁盘
      disk.main = {
        # 要生成的磁盘镜像的大小，4GB 足够我使用，可以按需调整
        # Validation Failed: {"resource":"ReleaseAsset","code":"custom","field":"size","message":"size must be less than or equal to 2147483648"}
        imageSize = "2047M";
        # 磁盘路径。Disko 生成磁盘镜像时，实际上是启动一个 QEMU 虚拟机走一遍安装流程。
        # 因此无论你的 VPS 上的硬盘识别成 sda 还是 vda，这里都以 Disko 的虚拟机为准，指定 vda。
        device = "/dev/vda";
        type = "disk";
        # 定义这块磁盘上的分区表
        content = {
          # 使用 GPT 类型分区表。Disko 对 MBR 格式分区的支持似乎有点问题。
          type = "gpt";
          # 分区列表
          partitions = {
            # GPT 分区表不存在 MBR 格式分区表预留给 MBR 主启动记录的空间，因此这里需要预留
            # 硬盘开头的 1MB 空间给 MBR 主启动记录，以便后续 Grub 启动器安装到这块空间。
            # boot = {
            #   size = "1M";
            #   type = "EF02"; # for grub MBR
            #   # 优先级设置为最高，保证这块空间在硬盘开头
            #   priority = 0;
            # };

            # ESP 分区，或者说是 boot 分区。这套配置理论上同时支持 EFI 模式和 BIOS 模式启动的 VPS。
            ESP = {
              name = "ESP";
              # 根据我个人的需求预留 512MB 空间。如果你的 boot 分区占用更大/更小，可以按需调整。
              size = "512M";
              type = "EF00";
              # 优先级设置成第二高，保证在剩余空间的前面
              priority = 0;
              # 格式化成 FAT32 格式
              content = {
                type = "filesystem";
                format = "vfat";
                # 用作 Boot 分区，Disko 生成磁盘镜像时根据此处配置挂载分区，需要和 fileSystems.* 一致
                mountpoint = "/boot";
                mountOptions = ["fmask=0077" "dmask=0077"];
                extraArgs = ["-n" "NixBoot"];
              };
            };

            # 存放 NixOS 系统的分区，使用剩下的所有空间。
            # 用作 Nix 分区，Disko 生成磁盘镜像时根据此处配置挂载分区，需要和 fileSystems.* 一致
            nix = {
              size = "100%";
              priority = 1;
              # 格式化成 Btrfs，可以按需修改
              content = {
                type = "btrfs";
                mountpoint = "/nix";
                mountOptions = ["compress-force=zstd"];
                extraArgs = ["-L" "NixOS"];
                subvolumes = {
                  "persistent" = {
                    mountpoint = "/nix/persistent";
                  };
                };
              };
            };
          };
        };
      };

      # 由于我开了 Impermanence，需要声明一下根分区是 tmpfs，以便 Disko 生成磁盘镜像时挂载分区
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = ["relatime" "mode=755"];
      };
    };
  };

  # 由于我们没有让 Disko 管理 fileSystems.* 配置，我们需要手动配置
  # 根分区，由于我开了 Impermanence，所以这里是 tmpfs
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["relatime" "mode=755"];
  };

  # /nix 分区，是磁盘镜像上的第三个分区。由于我的 VPS 将硬盘识别为 sda，因此这里用 sda3。如果你的 VPS 识别结果不同请按需修改
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/NixOS";
    # device = "/dev/sda3";
    fsType = "btrfs";
    options = ["compress-force=zstd"];
  };

  # /boot 分区，是磁盘镜像上的第二个分区。由于我的 VPS 将硬盘识别为 sda，因此这里用 sda2。如果你的 VPS 识别结果不同请按需修改
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NixBoot";
    # device = "/dev/sda2";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };
  environment.persistence."/nix/persistent" = {
    hideMounts = false;

    directories = [
      "/home"
      "/root"
      "/var"
      "/workspace"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };
  # swapDevices = [
  #   {
  #     device = "/var/lib/swapfile";
  #     size = 16 * 1024; # 16GiB
  #   }
  # ];
  environment.variables = {
    GOPROXY = "https://goproxy.cn,direct";
  };
}
