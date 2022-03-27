package main

import (
	"os"

	"github.com/drn/dots/pkg/cache"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

func home() {
	cache.Log("ip-home", 5)
	ip := run.Capture("dig +short %s +tries=1 +time=1", os.Getenv("HOME_WAN"))
	if !isValid(ip) {
		os.Exit(1)
	}
	cache.Write("ip-home", ip)
	log.Info(ip)
}
