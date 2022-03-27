package main

// home-scp sends the specified file home via scp

import (
	"fmt"
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

var homeUser string = os.Getenv("HOME_USER")
var homeWAN string = os.Getenv("HOME_WAN")
var homeLAN string = os.Getenv("HOME_LAN")

func main() {
	if len(os.Args) < 2 {
		log.Error("Usage: home-scp <filepath> [destination {~}]")
		os.Exit(1)
	}
	source := os.Args[1]
	destination := "~"
	if len(os.Args) > 2 {
		destination = os.Args[2]
	}

	run.Verbose("scp %s %s:%s", source, address(), destination)
}

// returns local or remote address user@endpoint if laptop is on home network
// or not
func address() string {
	endpoint := homeWAN
	// compare current IP to home network IP
	if run.Capture("ip") == run.Capture("dig +short %s", homeWAN) {
		endpoint = homeLAN
	}
	return fmt.Sprintf(
		"%s@%s",
		homeUser,
		endpoint,
	)
}
