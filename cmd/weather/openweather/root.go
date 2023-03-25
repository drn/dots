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
// eg. 敖 49°
func Info() string {
	json := json()
	if json == "" || jsoniter.Get([]byte(json), "cod").ToInt() != 200 {
		return ""
	}
	return fmt.Sprintf("%s %.0f°", conditions(json), temperature(json))
}

func temperature(json string) float64 {
	temp := jsoniter.Get([]byte(json), "main", "temp").ToFloat64()
	return math.Round(temp)
}

// For details, see:
// - https://openweathermap.org/weather-conditions#Weather-Condition-Codes
// - https://www.nerdfonts.com/cheat-sheet (mdi-weather)
func conditions(json string) string {
	main := jsoniter.Get([]byte(json), "weather", 0, "id").ToInt()
	switch main {
	case 200, 201, 202, 230, 231, 232:
		// Thunderstorm (with rain)
		return "\ufb7c "
	case 210, 211, 212, 221:
		// Thunderstorm (no rain)
		return "\ufa92"
	case 300, 301, 302, 310, 311, 312, 313, 314, 321:
		// Drizzle
		return "\ufa96"
	case 500, 501, 502, 503, 504, 511, 520, 521, 522, 531:
		// Rain
		return "\ufa95"
	case 600, 601, 602, 611, 612, 613, 615, 616, 620, 621, 622:
		// Mist, Smoke, Haze, Dust, Fog, Sand, Dust, Ash
		return "\ufa97"
	case 701, 711, 721, 731, 741, 751, 761, 762:
		return "\ufa90"
	case 771, 781:
		// Squall, Tornado
		return "\ue351 "
	case 800:
		// Clear
		if isNight(json) {
			return "\ufa93"
		}
		return "\ufa98"
	case 801, 802, 803, 804:
		// Clouds
		return "\ufa94"
	}
	// Unknown
	return "\ue348 "
}

func isNight(json string) bool {
	icon := jsoniter.Get([]byte(json), "weather", 0, "icon").ToString()
	return icon[len(icon)-1:] == "n"
}

func json() string {
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
