package cli

import (
	"fmt"
	"net"

	"github.com/117503445/goutils"
	"github.com/rs/zerolog/log"
)

func setTestNet(c *cmdTestNet) {
	// exp: 172.19.0.3/16
	// network: 172.19
	// mask: 16
	getNetworkMask := func() (string, string) {
		interfaces, err := net.Interfaces()
		if err != nil {
			log.Fatal().Err(err).Send()
		}
		for _, iface := range interfaces {
			if iface.Name == "br0" {
				addrs, err := iface.Addrs()
				if err != nil {
					log.Fatal().Err(err).Send()
				}
				for _, addr := range addrs {
					var ipnet *net.IPNet
					switch v := addr.(type) {
					case *net.IPNet:
						ipnet = v
					case *net.IPAddr:
						ipnet = &net.IPNet{IP: v.IP, Mask: net.CIDRMask(32, 32)} // 默认设置为/32，对于非网络地址情况
					}

					if ipnet != nil && !ipnet.IP.IsLoopback() {
						if ipnet.IP.To4() != nil {
							ones, _ := ipnet.Mask.Size() // 获取掩码大小
							network := ipnet.IP.Mask(ipnet.Mask)

							networkStr := ""
							switch ones {
							case 8:
								networkStr = fmt.Sprintf("%d", network[0])
							case 16:
								networkStr = fmt.Sprintf("%d.%d", network[0], network[1])
							case 24:
								networkStr = fmt.Sprintf("%d.%d.%d", network[0], network[1], network[2])
							default:
								log.Fatal().Int("mask", ones).Msg("Unsupported mask size")
							}
							return networkStr, fmt.Sprintf("%d", ones)
						}
					}
				}
			}
		}
		log.Fatal().Msg("no ip found")
		return "", ""
	}

	ip, mask := getNetworkMask()
	log.Debug().Str("ip", ip).Str("mask", mask).Send()

	err := goutils.WriteToml("/workspace/assets/flake/nodes/nixos-test/net.toml", map[string]string{
		"gateway": fmt.Sprintf("%s")
	})
	if err != nil {
		log.Fatal().Err(err).Send()
	}
}
