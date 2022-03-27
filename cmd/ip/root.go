package main

import (
	"fmt"
	"os"
	"regexp"

	"github.com/drn/dots/pkg/cache"
	"github.com/drn/dots/pkg/log"
	"github.com/jessevdk/go-flags"
)

var services = []string{
	"ipv4.icanhazip.com",
	"wtfismyip.com/text",
	"ipecho.net/plain",
	"ipinfo.io/ip",
	"ifconfig.me",
	"ifconfig.co",
	"l2.io/ip",
}

// Options - Parsed input flags schema
var opts struct {
	Local  bool `short:"l" long:"local" description:"Return local IP of the specified interface (defaults to en0)"`
	Router bool `short:"r" long:"router" description:"Return IP of LAN router"`
	Home   bool `short:"h" long:"home" description:"Return IP of home network"`
}

func main() {
	args, err := flags.ParseArgs(&opts, os.Args)
	if flags.WroteHelp(err) {
		return
	}
	if err != nil {
		fmt.Println()
		flags.ParseArgs(&opts, []string{"--help"})
		os.Exit(1)
	}

	if opts.Local {
		if len(args) > 1 {
			local(args[1])
		} else {
			local("en0")
		}
	} else if opts.Router {
		router()
	} else if opts.Home {
		home()
	} else {
		external()
	}
}

// Read IP from input cache file if less than 5min TTL
func cacheRead(cachePath string) {
	ip := cache.Read(cachePath, 5)
	if ip != "" {
		log.Info(ip)
		os.Exit(0)
	}
}

func isValid(data string) bool {
	result, _ := regexp.MatchString("^\\d+.\\d+.\\d+.\\d+$", data)
	return result
}
