package common

import (
	"net"

	"github.com/117503445/goutils/gexec"
	"github.com/rs/zerolog/log"
)

func getInterfaceIp(ifaceName string) string {
	// log.Debug().Msg("getHostIp")
	interfaces, err := net.Interfaces()
	if err != nil {
		log.Fatal().Err(err).Send()
	}

	for _, iface := range interfaces {
		if iface.Name == ifaceName {
			addrs, err := iface.Addrs()
			if err != nil {
				log.Warn().Err(err).Msg("Error retrieving addresses for interface")
				continue
			}
			for _, addr := range addrs {
				var ip net.IP
				switch v := addr.(type) {
				case *net.IPNet:
					ip = v.IP
				case *net.IPAddr:
					ip = v.IP
				}
				return ip.String()
			}
		}
	}
	return ""
}

func GetHostIp() string {
	hostIp := getInterfaceIp("eth0")
	if hostIp == "" {
		hostIp = getInterfaceIp("br0")
		if hostIp == "" {
			log.Fatal().Msg("hostIp is empty")
		}
	}
	return hostIp
}

func MustSetTestNet() {
	// 确保 br0 存在
	interfaceExists := func(ifaceName string) bool {
		interfaces, err := net.Interfaces()
		if err != nil {
			log.Fatal().Err(err).Send()
		}

		for _, iface := range interfaces {
			if iface.Name == ifaceName {
				return true
			}
		}
		return false
	}
	brExists := func() bool {
		return interfaceExists("br0") && interfaceExists("br1")
	}
	if !brExists() {
		log.Info().Msg("br0 or br1 not exists, create them")

		_, err := gexec.Run(
			gexec.Command("/workspace/scripts/run-vm/br.sh"),
		)
		if err != nil {
			log.Fatal().Err(err).Send()
		}
	}
	if !brExists() {
		log.Fatal().Msg("br still not exists")
	}
}
