// Package openweather - https://openweathermap.org/
package openweather

import (
	"fmt"
	"math"
	"os"
	"strings"

	"github.com/drn/dots/pkg/run"
	jsoniter "github.com/json-iterator/go"
)

// Info - symbol temperature
// eg. 󰖑 49°
func Info() string {
	data := fetchWeatherJSON()
	if data == "" || jsoniter.Get([]byte(data), "cod").ToInt() != 200 {
		return ""
	}
	return fmt.Sprintf("%s %.0f°", conditions(data), temperature(data))
}

func temperature(data string) float64 {
	temp := jsoniter.Get([]byte(data), "main", "temp").ToFloat64()
	return math.Round(temp)
}

// For details, see:
// - https://openweathermap.org/weather-conditions#Weather-Condition-Codes
// - https://www.nerdfonts.com/cheat-sheet (mdi-weather)
func conditions(data string) string {
	code := jsoniter.Get([]byte(data), "weather", 0, "id").ToInt()
	switch {
	case code >= 200 && code <= 232 && (code <= 202 || code >= 230):
		// Thunderstorm (with rain)
		return "\U000f067e "
	case code >= 210 && code <= 221:
		// Thunderstorm (no rain)
		return "\U000f0593"
	case code >= 300 && code <= 321:
		// Drizzle
		return "\U000f0597"
	case code >= 500 && code <= 531:
		// Rain
		return "\U000f0596"
	case code >= 600 && code <= 622:
		// Snow
		return "\U000f0598"
	case code >= 701 && code <= 762:
		// Mist, Smoke, Haze, Dust, Fog, Sand, Ash
		return "\U000f0591"
	case code == 771 || code == 781:
		// Squall, Tornado
		return "\ue351 "
	case code == 800:
		// Clear
		if isNight(data) {
			return "\U000f0594"
		}
		return "\U000f0599"
	case code >= 801 && code <= 804:
		// Clouds
		return "\U000f0595"
	default:
		return "\ue348 "
	}
}

func isNight(data string) bool {
	icon := jsoniter.Get([]byte(data), "weather", 0, "icon").ToString()
	return len(icon) > 0 && icon[len(icon)-1:] == "n"
}

func fetchWeatherJSON() string {
	coords := gps()
	if len(coords) != 2 {
		return ""
	}
	return run.Capture(
		"curl -s 'https://%s?lat=%s&lon=%s&appid=%s&units=imperial'",
		"api.openweathermap.org/data/2.5/weather",
		coords[0],
		coords[1],
		os.Getenv("OPEN_WEATHER_API_KEY"),
	)
}

func gps() []string {
	coords := run.Capture("gps")
	return strings.Split(coords, ",")
}
