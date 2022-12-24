// Outputs the current weather and temperature for use with status lines.
package main

import (
	"fmt"
	"os"

	"github.com/drn/dots/cmd/weather/openweather"
	"github.com/drn/dots/cmd/weather/wttr"
	"github.com/drn/dots/pkg/cache"
	"github.com/drn/dots/pkg/log"
	"github.com/jessevdk/go-flags"
)

// Options - Parsed input flags schema
var opts struct {
	SkipCache bool `short:"x" long:"skip-cache" description:"Bypasses cache"`
}

func main() {
	_, err := flags.ParseArgs(&opts, os.Args)
	if flags.WroteHelp(err) {
		return
	}
	if err != nil {
		fmt.Println()
		flags.ParseArgs(&opts, []string{"--help"})
		os.Exit(1)
	}

	if !opts.SkipCache {
		cache.Log("weather", 15)
	}

	weather := weather()
	cache.Write("weather", weather)
	log.Info(weather)
}

func weather() string {
	weather := openweather.Info()
	if weather != "" {
		return weather
	}
	weather = wttr.Info()
	if weather != "" {
		return weather
	}
	os.Exit(1)
	return ""
}
