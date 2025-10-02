package cli

import (
	"fmt"
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
	var imgs []string

	// 如果 c.Host 为空，则 hosts 是 /workspace/data/img/%v.img 的 %v 列表
	// 否则 hosts 是 [c.Host]
	var hosts []string
	if c.Host != "" {
		hosts = []string{c.Host}
	} else {
		// 获取所有 img 文件，提取主机名
		imgFiles, err := filepath.Glob("/workspace/data/img/*.img")
		if err != nil {
			log.Fatal().Err(err).Send()
		}

		for _, imgFile := range imgFiles {
			base := filepath.Base(imgFile)
			host := strings.TrimSuffix(base, filepath.Ext(base))
			hosts = append(hosts, host)
		}
	}
	log.Info().Strs("hosts", hosts).Send()

	// 根据 hosts 生成 imgs
	for _, host := range hosts {
		imgs = append(imgs, fmt.Sprintf("/workspace/data/img/%v.img", host))
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
			Name    string
			Cmdline string
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
				log.Debug().Str("k", k).Str("v", v).Send()
				// k 必须以 hosts 中的某个元素，作为 start with
				shouldInclude := false
				for _, host := range hosts {
					if strings.HasPrefix(k, host) {
						shouldInclude = true
						break
					}
				}

				if !shouldInclude {
					continue
				}

				proc := &procInfo{Name: k, Cmdline: v}

				procs = append(procs, proc)
			}
			if len(procs) == 0 {
				log.Fatal().Msg("no process found")
			}
			return procs
		}
		procs := readProcfile()
		log.Info().Interface("procs", procs).Send()

		var wg sync.WaitGroup

		// TODO: color or log
		for _, proc := range procs {
			wg.Add(1)
			go func() {
				defer wg.Done()

				_, err := gexec.Run(
					gexec.Command(proc.Cmdline),
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
