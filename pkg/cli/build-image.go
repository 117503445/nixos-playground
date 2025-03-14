package cli

import (
	"fmt"
	"io"
	"net"
	"os"

	"github.com/117503445/goutils/gexec"
	"github.com/117503445/nixos-playground/pkg/common"
	"github.com/rs/zerolog/log"
)

func buildImg(c *cmdBuildImg) {
	log.Info().Msg("cmdBuildImg")

	getHostIp := func(ifaceName string) string {
		// log.Debug().Msg("getHostIp")
		interfaces, err := net.Interfaces()
		if err != nil {
			log.Fatal().Err(err).Send()
		}

		for _, iface := range interfaces {
			if iface.Name == ifaceName {
				addrs, err := iface.Addrs()
				if err != nil {
					log.Warn().Err(err).Msg("Error retrieving addresses for interface")
					continue
				}
				for _, addr := range addrs {
					var ip net.IP
					switch v := addr.(type) {
					case *net.IPNet:
						ip = v.IP
					case *net.IPAddr:
						ip = v.IP
					}
					return ip.String()
				}
			}
		}
		return ""
	}
	var nixCacheUrl string
	if !c.NixCacheDisable {
		hostIp := getHostIp("eth0")
		if hostIp == "" {
			hostIp = getHostIp("br0")
			if hostIp == "" {
				log.Fatal().Msg("hostIp is empty")
			}
		}
		nixCacheUrl = fmt.Sprintf("http://%s:8000", hostIp)
		log.Debug().Str("hostIp", hostIp).Str("nixCacheUrl", nixCacheUrl).Send()
	} else {
		nixCacheUrl = "https://cache.nixos.org"
	}

	dirBuildImg := fmt.Sprintf("%s/build-img", common.DirLog)
	if err := os.MkdirAll(dirBuildImg, 0755); err != nil {
		log.Fatal().Err(err).Str("dirBuildImg", dirBuildImg).Send()
	}

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
		// gexec.Command("docker build --quiet -t 117503445/nix-builder -f ./scripts/docker/nix.Dockerfile ."),
		gexec.Commands([]string{
			"docker", "build", "--quiet",
			"-t", "117503445/nix-builder",
			"-f", "./scripts/docker/nix.Dockerfile",
			"--build-arg", "BASE_IMAGE=" + c.NixBaseImage,
			".",
		}),
	)
	if err != nil {
		log.Fatal().Err(err).Send()
	}

	for _, node := range nodes {
		buildImg := func() {
			log.Info().Str("node", node).Msg("BuildImg")

			fileLog := fmt.Sprintf("%s/%s.log", dirBuildImg, node)
			cmd := gexec.Commands([]string{
				"docker", "run", "--rm", "--privileged",
				"-e", "NAME=" + node,
				"-e", "NIX_CACHE_URL=" + nixCacheUrl,
				"-e", "HTTP_PROXY=" + c.HttpProxy,
				"-v", "/workspace/assets/flake:/workspace",
				"-v", "NIXSTORE:/nix/store",
				"-v", "/workspace/data/img:/data",
				"-v", "/workspace/scripts/mk-img.sh:/entrypoint",
				"117503445/nix-builder",
			})
			log.Info().Str("cmd", cmd.String()).Str("fileLog", fileLog).Msg("Executing")
			f, err := os.OpenFile(fileLog, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
			if err != nil {
				log.Fatal().Err(err).Send()
			}

			_, err = gexec.Run(
				cmd,
				&gexec.RunCfg{
					DisableLog: true,
					Writers: []io.Writer{
						os.Stdout,
						f,
					},
				},
			)
			if err != nil {
				log.Fatal().Err(err).Send()
			}

			log.Info().Str("cmd", cmd.String()).Str("fileLog", fileLog).Msg("Executed")
		}

		buildImg()
	}

}
