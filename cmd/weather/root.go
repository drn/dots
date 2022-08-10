// Outputs the current weather and temperature for use with status lines.
package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/drn/dots/pkg/cache"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
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
	weather := run.Capture("curl -s 'wttr.in?u&format=%%t+%%x'")
	parts := strings.Split(weather, " ")
	if len(parts) < 2 {
		os.Exit(1)
	}
	temp := parts[0]
	condition := parts[1]

	output := fmt.Sprintf("%c %s", conditionSymbol(condition), formatTemp(temp))
	cache.Write("weather", output)
	log.Info(output)
}

func formatTemp(temp string) string {
	return temp[1 : len(temp)-1]
}

// For details, see:
// - https://github.com/chubin/wttr.in/blob/master/lib/constants.py
// - https://www.nerdfonts.com/cheat-sheet (mdi-weather)
func conditionSymbol(condition string) rune {
	switch condition {
	case "mmm", "mm": // VeryCloudy, Cloudy
		return '\ufa8f'
	case "=": // Fog
		return '\ufa90'
	case "///", "//": // HeavyRain, HeavyShowers
		return '\ufa95'
	case "**", "*/*", "*": // HeavySnow, HeavySnowShowers, LightSnow
		return '\ufa97'
	case "/", ".": // LightRain, LightShowers
		return '\ufa96'
	case "x", "x/": // LightSleet, LightSleetShowers
		return '\ufa91'
	case "*/": // LightSnowShowers
		return '\ufb7d'
	case "m": // PartlyCloudy
		return '\ufa94'
	case "o": // Sunny
		return '\ufa98'
	case "/!/", "!/": // ThunderyHeavyRain, ThunderyShowers
		return '\ufb7c'
	case "*!*": // ThunderySnowShowers
		return '\ufa92'
	}
	// Unknown
	return '\ue348'
}
