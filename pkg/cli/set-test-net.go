package cli

import (
	"github.com/117503445/nixos-playground/pkg/common"
	"github.com/rs/zerolog/log"
)

func setTestNet(c *cmdTestNet) {
	ip := common.GetHostIp()
	log.Info().Str("ip", ip).Send()
}
