// Outputs the lat,lng of the current external IP
package main

import (
	"os"
	"strings"

	"github.com/drn/dots/pkg/cache"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
	jsoniter "github.com/json-iterator/go"
)

func main() {
	cache.Log("gps", 15)
	coords := coordinates()
	if coords == "" {
		os.Exit(1)
	}
	log.Info(coords)
	cache.Write("gps", coords)
}

func coordinates() string {
	info := capture("curl https://ipinfo.io/$(ip)")
	return jsoniter.Get([]byte(info), "loc").ToString()
}

func capture(command string, args ...interface{}) string {
	data := run.Capture(command+" 2>/dev/null", args...)
	return strings.Trim(data, "\"")
}
