package main

import (
	"fmt"
	"os"
	"regexp"

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
	Local bool `short:"l" long:"local" description:"Return local IP of the specified interface (defaults to en0)"`
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
	} else {
		external()
	}
}

func isValid(data string) bool {
	result, _ := regexp.MatchString("^\\d+.\\d+.\\d+.\\d+$", data)
	return result
}
