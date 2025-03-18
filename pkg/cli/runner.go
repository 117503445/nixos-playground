package cli

import (
	"io"
	"os"
	"sync"

	"github.com/117503445/goutils"
	"github.com/117503445/goutils/gexec"
	"github.com/rs/zerolog/log"
)

func runner(c *cmdRunner) {

	fileImg := "/workspace/data/vm.img"

	func() {
		// download
		if !goutils.FileExists(fileImg) {
			log.Info().Str("file", fileImg).Str("url", c.DownloadUrl).Msg("img not exists, download it")
			// err := os.MkdirAll(dirDownloads, 0755)
			// if err != nil {
			// 	goutils.Logger.Fatal().Err(err).Msg("create dir failed")
			// }
			_, err := gexec.Run(
				gexec.Commands([]string{"aria2c", "-d", "/workspace/data", "-o", "vm.img", c.DownloadUrl}),
				&gexec.RunCfg{
					Writers: []io.Writer{
						os.Stdout,
					},
				},
			)
			if err != nil {
				log.Fatal().Err(err).Msg("download failed")
			}

			if !goutils.FileExists("/workspace/data/vm.img") {
				log.Fatal().Msg("download failed")
			}
		}
	}()

	func() {
		_, err := gexec.Run(
			gexec.Command("/workspace/script/br.sh"),
		)
		if err != nil {
			log.Fatal().Err(err).Send()
		}
	}()

	var wg sync.WaitGroup

	wg.Add(1)
	go func() {
		defer wg.Done()
		_, err := gexec.Run(
			gexec.Command("/usr/bin/novnc --vnc localhost:5900 --listen 6080"),
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

	wg.Add(1)
	go func() {
		defer wg.Done()
		_, err := gexec.Run(
			gexec.Command("qemu-system-x86_64 --enable-kvm -smp sockets=1,cores=2,threads=1 -m 2000M -drive file=/workspace/data/vm.img,format=raw -vnc 0.0.0.0:0 -nic bridge,br=br0,model=virtio-net-pci,mac=52:54:00:12:34:00 -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd"),
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

	wg.Wait()
}
