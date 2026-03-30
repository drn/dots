// Package wttr - https://github.com/chubin/wttr.in
package wttr

import (
	"fmt"
	"strings"

	"github.com/drn/dots/pkg/run"
)

// Info - symbol temperature
// eg. 󰖑 49°
func Info() string {
	weather := run.Capture("curl -s -m 0.5 'wttr.in?u&format=%%t+%%x'")
	parts := strings.Split(weather, " ")
	if len(parts) < 2 {
		return ""
	}
	temp := parts[0]
	condition := parts[1]

	return fmt.Sprintf("%c %s", conditionSymbol(condition), formatTemp(temp))
}

func formatTemp(temp string) string {
	if len(temp) < 2 {
		return temp
	}
	return temp[1 : len(temp)-1]
}

// For details, see:
// - https://github.com/chubin/wttr.in/blob/master/lib/constants.py
// - https://www.nerdfonts.com/cheat-sheet (mdi-weather)
func conditionSymbol(condition string) rune {
	switch condition {
	case "mmm", "mm": // VeryCloudy, Cloudy
		return '\U000f0590'
	case "=": // Fog
		return '\U000f0591'
	case "///", "//": // HeavyRain, HeavyShowers
		return '\U000f0596'
	case "**", "*/*", "*": // HeavySnow, HeavySnowShowers, LightSnow
		return '\U000f0598'
	case "/", ".": // LightRain, LightShowers
		return '\U000f0597'
	case "x", "x/": // LightSleet, LightSleetShowers
		return '\U000f0592'
	case "*/": // LightSnowShowers
		return '\U000f067f'
	case "m": // PartlyCloudy
		return '\U000f0595'
	case "o": // Sunny
		return '\U000f0599'
	case "/!/", "!/": // ThunderyHeavyRain, ThunderyShowers
		return '\U000f067e'
	case "*!*": // ThunderySnowShowers
		return '\U000f0593'
	}
	// Unknown
	return '\ue348'
}
