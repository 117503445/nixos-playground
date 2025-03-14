package common

import (
	"os"

	"github.com/rs/zerolog/log"
)

const DirData = "/workspace/data"
const DirImg = "/workspace/data/img"
const DirVm = "/workspace/data/vm"

var DirLog = "/workspace/data/logs/" + RunId

func init() {
	dirs := []string{DirData, DirImg, DirLog, DirVm}
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			log.Fatal().Err(err).Send()
		}
	}
}
