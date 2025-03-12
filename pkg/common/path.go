package common

import (
	"os"

	"github.com/rs/zerolog/log"
)

const DirData = "/workspace/data"
const DirIso = "/workspace/data/iso"

func init() {
	dirs := []string{DirData, DirIso}
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			log.Fatal().Err(err).Send()
		}
	}
}
