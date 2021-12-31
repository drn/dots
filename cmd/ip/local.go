package main

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

func local(networkInterface string) {
	data := run.Capture(
		"/sbin/ifconfig %s | awk '/inet /{print $2}'",
		networkInterface,
	)
	if !isValid(data) {
		os.Exit(1)
	}
	log.Info(data)
}
