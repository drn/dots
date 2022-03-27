package main

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

func home() {
	ip := run.Capture("dig +short %s", os.Getenv("HOME_WAN"))
	log.Info(ip)
}
