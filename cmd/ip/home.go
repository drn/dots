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
	ip := run.Capture("dig +short %s", os.Getenv("HOME_WAN"))
	cache(cachePath, ip)
	log.Info(ip)
}
