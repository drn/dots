// home-scp sends the specified file home via scp
package main

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

var homeUser = os.Getenv("HOME_USER")
var homeWAN = os.Getenv("HOME_WAN")
var homeLAN = os.Getenv("HOME_LAN")

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

	run.Verbose("scp %s %s@%s:%s", source, homeUser, homeWAN, destination)
}
