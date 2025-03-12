package cli

import (
	"github.com/alecthomas/kong"
	kongtoml "github.com/alecthomas/kong-toml"
	"github.com/rs/zerolog/log"
)

type cmdBuildImg struct {
	HttpProxy string
}

func (c *cmdBuildImg) Run() error {
	buildImg(c)
	return nil
}

type cmdDeploy struct {
}

var cli struct {
	BuildImg cmdBuildImg `cmd:"" help:"build img"`
	Deploy   cmdDeploy   `cmd:"" help: "deploy"`
}

func CliLoad() {
	ctx := kong.Parse(&cli, kong.Configuration(kongtoml.Loader, "/workspace/config.toml"))
	log.Info().Interface("cli", cli).Send()
	err := ctx.Run()
	if err != nil {
		log.Fatal().Err(err).Send()
	}
}
