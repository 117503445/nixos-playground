package cli

import (
	"fmt"
	"net"
	"strings"

	"github.com/117503445/goutils"
	"github.com/117503445/nixos-playground/pkg/common"
	"github.com/rs/zerolog/log"
)

func setTestNet(c *cmdTestNet) {
	// exp: 172.19.0.3/16
	// network: 172.19.0.0
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

							return network.String(), fmt.Sprintf("%d", ones)
						}
					}
				}
			}
		}
		log.Fatal().Msg("no ip found")
		return "", ""
	}

	network, mask := getNetworkMask()
	log.Debug().Str("ip", network).Str("mask", mask).Send()

	gateway := strings.TrimSuffix(network, ".0") + ".1"
	address := fmt.Sprintf("%s.10/%s", strings.TrimSuffix(network, ".0"), mask)

	log.Debug().Str("gateway", gateway).Str("address", address).Send()

	err := goutils.WriteToml(common.FileTestNet, map[string]string{
		"gateway": gateway,
		"address": address,
	})
	if err != nil {
		log.Fatal().Err(err).Send()
	}
}
