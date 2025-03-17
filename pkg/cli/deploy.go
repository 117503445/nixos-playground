package cli

import (
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/117503445/goutils"
	"github.com/117503445/goutils/gexec"
	"github.com/117503445/nixos-playground/pkg/common"
	"github.com/rs/zerolog/log"
)

func runDeploy(c *cmdDeploy) {
	findTestIp := func() string {
		var m map[string]string
		err := goutils.ReadToml(common.FileTestNet, &m)
		if err != nil {
			log.Fatal().Err(err).Send()
			return ""
		}
		address, ok := m["address"]
		if !ok {
			log.Fatal().Interface("m", m).Msg("gateway not found")
			return ""
		}
		splits := strings.Split(address, "/")
		if len(splits) != 2 {
			log.Fatal().Str("address", address).Msg("invalid address")
			return ""
		}
		return splits[0]
	}
	testIp := findTestIp()
	log.Info().Str("testIp", testIp).Send()

	sendFlake := func() {
		_, err := gexec.Run(
			gexec.Commands(
				[]string{
					"rsync",
					"-az",
					"-e",
					"ssh -i /workspace/scripts/ssh/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null",
					"/workspace/assets/flake/",
					fmt.Sprintf("root@%v:/etc/nixos", testIp),
				},
			),
			&gexec.RunCfg{
				Writers: []io.Writer{
					os.Stdout,
				},
			},
		)
		if err != nil {
			log.Fatal().Err(err).Send()
		}
	}
	sendFlake()

	switchOs := func() {

		cache := "https://mirrors.ustc.edu.cn/nix-channels/store"
		hostName := "nixos-test"

		_, err := gexec.Run(
			gexec.Commands(
				[]string{
					"ssh",
					"-i", "/workspace/scripts/ssh/id_ed25519",
					"-o", "StrictHostKeyChecking=no",
					"-o", "UserKnownHostsFile=/dev/null",
					fmt.Sprintf("root@%v", testIp),
					fmt.Sprintf("sh -c 'nixos-rebuild switch --flake /etc/nixos#%v --accept-flake-config --print-build-logs --show-trace --option substituters %v'", hostName, cache),
				},
			),
			&gexec.RunCfg{
				Writers: []io.Writer{
					os.Stdout,
				},
			},
		)
		if err != nil {
			log.Fatal().Err(err).Send()
		}
	}
	switchOs()

}
