// Opens browser to the router's IP if available
package main

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

func main() {
	ip := run.Capture("ip --router")
	if ip == "" {
		log.Error("No connectivity")
		os.Exit(1)
	}
	run.Verbose("open http://%s", ip)
}
