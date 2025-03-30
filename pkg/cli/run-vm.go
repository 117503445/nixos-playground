package cli

import (
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/117503445/goutils"
	"github.com/117503445/goutils/gexec"
	"github.com/117503445/nixos-playground/pkg/common"
	"github.com/rs/zerolog/log"
)

func runVm(c *cmdRunVm) {
	imgs, err := filepath.Glob("/workspace/data/img/*.img")
	if err != nil {
		log.Fatal().Err(err).Send()
	}
	log.Debug().Strs("imgs", imgs).Send()

	func() {
		// 确保 vm 目录下存在硬盘
		for _, img := range imgs {
			dest := filepath.Join(common.DirVm, filepath.Base(img))
			if !goutils.FileExists(dest) {
				log.Debug().Str("src", img).Str("dest", dest).Msg("copy img")
				err := goutils.CopyFile(img, dest)
				if err != nil {
					log.Fatal().Err(err).Send()
				}
			}
		}
	}()

	common.MustSetTestNet()

	// func() {
	// 	_, err := gexec.Run(
	// 		gexec.SetPwd("/workspace/scripts/run-vm", gexec.Command("goreman start")),
	// 		&gexec.RunCfg{
	// 			Writers: []io.Writer{
	// 				os.Stdout,
	// 			},
	// 		},
	// 	)
	// 	if err != nil {
	// 		log.Fatal().Err(err).Send()
	// 	}
	// }()

	func() {
		type procInfo struct {
			name    string
			cmdline string
		}

		// read Procfile and parse it.
		// https://github.com/mattn/goreman/blob/master/main.go
		readProcfile := func() []*procInfo {
			content, err := goutils.ReadText("/workspace/scripts/run-vm/Procfile")
			if err != nil {
				log.Fatal().Err(err).Send()
			}

			procs := []*procInfo{}
			for _, line := range strings.Split(string(content), "\n") {
				tokens := strings.SplitN(line, ":", 2)
				if len(tokens) != 2 || tokens[0][0] == '#' {
					continue
				}
				k, v := strings.TrimSpace(tokens[0]), strings.TrimSpace(tokens[1])
				proc := &procInfo{name: k, cmdline: v}

				procs = append(procs, proc)
			}
			if len(procs) == 0 {
				log.Fatal().Msg("no process found")
			}
			return procs
		}
		procs := readProcfile()

		var wg sync.WaitGroup

		// TODO: color or log
		for _, proc := range procs {
			wg.Add(1)
			go func() {
				defer wg.Done()

				_, err := gexec.Run(
					gexec.Command(proc.cmdline),
					&gexec.RunCfg{
						Writers: []io.Writer{
							os.Stdout,
						},
					},
				)
				if err != nil {
					log.Fatal().Err(err).Send()
				}
			}()
		}

		wg.Wait()
	}()
}
