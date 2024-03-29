// Outputs the machine's LAN IP, the router's IP, or the network's WAN IP
package main

import (
	"fmt"
	"os"
	"regexp"

	"github.com/jessevdk/go-flags"
)

// Options - Parsed input flags schema
var opts struct {
	Local    bool `short:"l" long:"local" description:"Return local IP of the specified interface (defaults to en0)"`
	Router   bool `short:"r" long:"router" description:"Return IP of LAN router"`
	Home     bool `short:"h" long:"home" description:"Return IP of home network"`
	Uncached bool `long:"uncached" description:"Bypass IP cache"`
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
		home(!opts.Uncached)
	} else {
		external(!opts.Uncached)
	}
}

func isValid(data string) bool {
	result, _ := regexp.MatchString("^\\d+.\\d+.\\d+.\\d+$", data)
	return result
}
