package main

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
	"github.com/drn/dots/pkg/run"
)

func home() {
	cachePath := path.FromHome(".dots/ip-home")
	checkCache(cachePath)
	ip := run.Capture("dig +short %s +tries=1 +time=1", os.Getenv("HOME_WAN"))
	if !isValid(ip) {
		os.Exit(1)
	}
	cache(cachePath, ip)
	log.Info(ip)
}
