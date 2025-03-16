package cli

import (
	"strings"

	"github.com/117503445/goutils/gexec"
	"github.com/rs/zerolog/log"
)

func runDeploy(c *cmdDeploy) {
	findTestIp := func() string {
		output, err := gexec.Run(
			gexec.Command("ip neigh show"),
		)
		if err != nil {
			log.Fatal().Err(err).Send()
		}
		for _, line := range strings.Split(output, "\n") {
			splits := strings.Split(line, " ")
			if len(splits) < 6 {
				continue
			}
			if splits[4] == "52:54:00:12:34:00" {
				return splits[0]
			}
		}
		log.Fatal().Msg("no test ip found")
		return ""
	}
	testIp := findTestIp()
	log.Info().Str("testIp", testIp).Send()

}
