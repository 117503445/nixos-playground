package common

import (
	"net"

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
