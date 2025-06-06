package main

import (
	"os"

	"github.com/117503445/goutils"
	"github.com/117503445/nixos-playground/pkg/cli"
	"github.com/117503445/nixos-playground/pkg/common"
	"github.com/rs/zerolog/log"
)

func init() {
	goutils.InitZeroLog(goutils.WithProduction{
		DirLog: common.DirLog,
	})
}

func main() {
	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal().Err(err).Send()
	}
	if cwd != "/workspace" {
		log.Fatal().Msg("please run in /workspace")
	}

	cli.CliLoad()
}
