package main

import (
	"os"
	"strings"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

func router() {
	info := run.Capture("netstat -nr | grep -m 1 default")
	fields := strings.Fields(info)
	if len(fields) < 2 || !isValid(fields[1]) {
		os.Exit(1)
	}
	log.Info(fields[1])
}
