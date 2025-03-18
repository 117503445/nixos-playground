package cli

import (
	"github.com/alecthomas/kong"
	kongtoml "github.com/alecthomas/kong-toml"
	"github.com/rs/zerolog/log"
)

type cmdBuildImg struct {
	HttpProxy       string
	NixCacheDisable bool
	NixBaseImage    string `default:"registry.cn-hangzhou.aliyuncs.com/117503445-mirror/sync:linux.amd64.docker.io.nixos.nix.latest"`
}

func (c *cmdBuildImg) Run() error {
	buildImg(c)
	return nil
}

type cmdDeploy struct {
}

func (c *cmdDeploy) Run() error {
	runDeploy(c)
	return nil
}

type cmdRunVm struct {
}

func (c *cmdRunVm) Run() error {
	runVm(c)
	return nil
}

type cmdTestNet struct {
}

func (c *cmdTestNet) Run() error {
	setTestNet(c)
	return nil
}

type cmdRunner struct {
	DownloadUrl string `default:"https://github.com/117503445/nixos-playground/releases/latest/download/nixos-test.img"`
}

func (c *cmdRunner) Run() error {
	runner(c)
	return nil
}

var cli struct {
	BuildImg cmdBuildImg `cmd:"" help:"build img"`
	Deploy   cmdDeploy   `cmd:"" help:"deploy"`
	RunVm    cmdRunVm    `cmd:"" help:"run vm"`
	SetTestNet cmdTestNet `cmd:"" help:"set nixos-test net info"`
	Runner cmdRunner `cmd:"" help:"run img in docker"`
}

func CliLoad() {
	ctx := kong.Parse(&cli, kong.Configuration(kongtoml.Loader, "/workspace/config.toml"))
	log.Info().Interface("cli", cli).Send()
	err := ctx.Run()
	if err != nil {
		log.Fatal().Err(err).Send()
	}
}
