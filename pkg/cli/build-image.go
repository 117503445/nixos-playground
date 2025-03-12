package cli

import (
	"os"

	"github.com/117503445/goutils/gexec"
	"github.com/rs/zerolog/log"
)

func buildImg(c *cmdBuildImg) {
	log.Info().Msg("cmdBuildImg")

	getSubDirs := func(dir string) []string {
		dirs := []string{}

		files, err := os.ReadDir(dir)
		if err != nil {
			log.Fatal().Err(err).Send()
		}
		for _, file := range files {
			if file.IsDir() {
				dirs = append(dirs, file.Name())
			}
		}
		return dirs
	}

	nodes := getSubDirs("/workspace/assets/flake/nodes")
	log.Debug().Strs("nodes", nodes).Send()

	_, err := gexec.Run(
		gexec.Command("docker build --quiet -t 117503445/nix-builder -f ./scripts/docker/nix.Dockerfile ."),
	)
	if err != nil {
		log.Fatal().Err(err).Send()
	}

	for _, node := range nodes {
		log.Info().Str("node", node).Msg("BuildImg")
	}

}
