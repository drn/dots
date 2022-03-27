package main

import (
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

func main() {
	condition := run.Capture("curl -s wttr.in?format=%%t+%%c")
	log.Info(condition)
}
