package openweather

import (
	"fmt"
	"testing"
)

func TestConditions(t *testing.T) {
	tests := []struct {
		code int
		want string
	}{
		// Thunderstorm with rain
		{200, "\ufb7c "},
		{201, "\ufb7c "},
		{202, "\ufb7c "},
		{230, "\ufb7c "},
		{231, "\ufb7c "},
		{232, "\ufb7c "},
		// Thunderstorm no rain
		{210, "\ufa92"},
		{211, "\ufa92"},
		{212, "\ufa92"},
		{221, "\ufa92"},
		// Drizzle
		{300, "\ufa96"},
		{301, "\ufa96"},
		{321, "\ufa96"},
		// Rain
		{500, "\ufa95"},
		{501, "\ufa95"},
		{531, "\ufa95"},
		// Snow
		{600, "\ufa97"},
		{601, "\ufa97"},
		{622, "\ufa97"},
		// Mist, Smoke, Haze, Dust, Fog, Sand, Ash
		{701, "\ufa90"},
		{711, "\ufa90"},
		{762, "\ufa90"},
		// Squall, Tornado
		{771, "\ue351 "},
		{781, "\ue351 "},
		// Clouds
		{801, "\ufa94"},
		{802, "\ufa94"},
		{804, "\ufa94"},
		// Unknown
		{999, "\ue348 "},
		{0, "\ue348 "},
	}

	for _, tt := range tests {
		data := buildWeatherJSON(tt.code, "01d")
		got := conditions(data)
		if got != tt.want {
			t.Errorf("conditions(code=%d) = %q, want %q", tt.code, got, tt.want)
		}
	}
}

func TestConditions_Clear_DayVsNight(t *testing.T) {
	day := buildWeatherJSON(800, "01d")
	if got := conditions(day); got != "\ufa98" {
		t.Errorf("conditions(800, day) = %q, want sun icon", got)
	}

	night := buildWeatherJSON(800, "01n")
	if got := conditions(night); got != "\ufa93" {
		t.Errorf("conditions(800, night) = %q, want moon icon", got)
	}
}

func TestConditions_ThunderstormBoundaries(t *testing.T) {
	// Codes 203-209 are undefined, should fall to default
	for code := 203; code <= 209; code++ {
		data := buildWeatherJSON(code, "01d")
		got := conditions(data)
		if got != "\ue348 " {
			t.Errorf("conditions(code=%d) = %q, want unknown icon", code, got)
		}
	}
	// Codes 222-229 are undefined, should fall to default
	for code := 222; code <= 229; code++ {
		data := buildWeatherJSON(code, "01d")
		got := conditions(data)
		if got != "\ue348 " {
			t.Errorf("conditions(code=%d) = %q, want unknown icon", code, got)
		}
	}
}

func buildWeatherJSON(code int, icon string) string {
	return fmt.Sprintf(`{"cod":200,"weather":[{"id":%d,"icon":"%s"}],"main":{"temp":72}}`, code, icon)
}
