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
  ];

  # 网络主机名
  networking.hostName = "router-test";

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
    nat.enable = false;

    # 关闭 DHCP，手动配置 IP
    useDHCP = false;
    # 手动设置 DNS
    nameservers = ["223.5.5.5" "223.6.6.6"];
    # 手动设置默认网关
    defaultGateway = {
      address = "172.19.0.1"; # TODO
      interface = "wan";
    };
    # 关闭 NixOS 自带的防火墙
    firewall.enable = false;

    nftables.flushRuleset = true;
    nftables.enable = true;
    nftables.ruleset = ''
      table inet filter {
        # enable flow offloading for better throughput
        # flowtable f {
        #   hook ingress priority 0;
        #   devices = { wan, lan };
        # }

        chain output {
          type filter hook output priority 100; policy accept;
        }

        chain input {
          type filter hook input priority filter; policy drop;

          # Allow established and related connections
          # ct state established,related counter accept

          # Allow trusted networks to access the router
          iifname {
            "lan",
          } counter accept

          # Allow returning traffic from wan
          iifname "wan" ct state { established, related } counter accept

          # Allow SSH
          iifname "wan" tcp dport 22 ct state new,established counter accept comment "Allow SSH"

          # Allow mosdns
          # iifname "wan" udp dport 15353 ct state new,established counter accept comment "Allow mosdns"

          # Allow metacubexd
          iifname "wan" tcp dport 9090 ct state new,established counter accept comment "Allow metacubexd"

          # Allow daed
          iifname "wan" tcp dport 2023 ct state new,established counter accept comment "Allow daed"

          # Allow traffic from lo interface
          iifname "lo" counter accept comment "Allow traffic from lo interface"

          iifname "wan" drop
        }

        chain forward {
          type filter hook forward priority filter; policy drop;

          # counter log prefix "traffic-20250106-0105"

          ip daddr 192.168.60.100 tcp dport 22 counter accept

          # enable flow offloading for better throughput
          # ip protocol { tcp, udp } flow offload @f

          # Allow trusted network WAN access
          iifname {
                  "lan",
          } oifname {
                  "wan",
          } counter accept comment "Allow trusted LAN to WAN"

          # Allow established WAN to return
          iifname {
                  "wan",
          } oifname {
                  "lan",
          } ct state established,related counter accept comment "Allow established back to LANs"
        }
      }

      table ip nat {
        chain prerouting {
          type nat hook prerouting priority -100; policy accept;

          tcp dport 2222 counter dnat to 192.168.60.100:22
        }

        # Setup NAT masquerading on the wan interface
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname "wan" counter masquerade
        }
      }
    '';
  };

  systemd.network = {
    enable = true;
    links = {
      "10-wan" = {
        matchConfig.PermanentMACAddress = "52:54:00:12:34:01";
        linkConfig.Name = "wan";
      };
      "10-lan" = {
        matchConfig.PermanentMACAddress = "52:54:00:12:34:02";
        linkConfig.Name = "lan";
      };
    };

    networks = {
      "wan" = {
        matchConfig.Name = "wan";
        address = ["172.19.0.11/16"];
        gateway = ["172.19.0.1"];
      };
      "lan" = {
        matchConfig.Name = "lan";
        networkConfig.DHCP = "no";
        address = ["192.168.60.1/24"];
      };
    };
  };

  boot.kernel.sysctl = {
    # if you use ipv4, this is all you need
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.all.send_redirects" = false; # for dae, https://github.com/daeuniverse/dae/blob/main/docs/en/user-guide/kernel-parameters.md
    "net.ipv4.conf.lan.send_redirects" = false; # for dae, https://github.com/daeuniverse/dae/blob/main/docs/en/user-guide/kernel-parameters.md

    # If you want to use it for ipv6
    "net.ipv6.conf.all.forwarding" = true;
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          "lan"
        ];
      };
      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      rebind-timer = 2000;
      renew-timer = 1000;
      subnet4 = [
        {
          id = 1;
          pools = [
            {
              pool = "192.168.60.100 - 192.168.60.120";
            }
          ];
          subnet = "192.168.60.1/24";
          reservations = [
            {
              hw-address = "52:54:98:76:54:82";
              ip-address = "192.168.60.100";
            }
          ];
        }
      ];
      valid-lifetime = 4000;
      option-data = [
        # 通告 192.168.100.1 为默认网关
        {
          "name" = "routers";
          "code" = 3;
          "data" = "192.168.60.1";
        }
        # 通告 192.168.100.1 为默认路由器
        {
          name = "domain-name-servers";
          code = 6;
          data = "192.168.60.1";
        }
      ];
    };
  };

  # services.tailscale = {
  #   enable = true;
  #   # useRoutingFeatures = "both";
  #   authKeyFile = ./tailscale-authkey;
  #   authKeyParameters = {
  #     ephemeral = false;
  #     preauthorized = true;
  #     baseURL = "https://headscale.be.wizzstudio.com:30000";
  #   };
  #   extraUpFlags = [
  #     "--advertise-routes=192.168.60.0/24"
  #     "--accept-routes=true"
  #     "--accept-dns=false"
  #   ];
  # };

  system.stateVersion = "24.11";
}
