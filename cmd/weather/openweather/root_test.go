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
		{200, "\U000f067e "},
		{201, "\U000f067e "},
		{202, "\U000f067e "},
		{230, "\U000f067e "},
		{231, "\U000f067e "},
		{232, "\U000f067e "},
		// Thunderstorm no rain
		{210, "\U000f0593"},
		{211, "\U000f0593"},
		{212, "\U000f0593"},
		{221, "\U000f0593"},
		// Drizzle
		{300, "\U000f0597"},
		{301, "\U000f0597"},
		{321, "\U000f0597"},
		// Rain
		{500, "\U000f0596"},
		{501, "\U000f0596"},
		{531, "\U000f0596"},
		// Snow
		{600, "\U000f0598"},
		{601, "\U000f0598"},
		{622, "\U000f0598"},
		// Mist, Smoke, Haze, Dust, Fog, Sand, Ash
		{701, "\U000f0591"},
		{711, "\U000f0591"},
		{762, "\U000f0591"},
		// Squall, Tornado
		{771, "\ue351 "},
		{781, "\ue351 "},
		// Clouds
		{801, "\U000f0595"},
		{802, "\U000f0595"},
		{804, "\U000f0595"},
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
	if got := conditions(day); got != "\U000f0599" {
		t.Errorf("conditions(800, day) = %q, want sun icon", got)
	}

	night := buildWeatherJSON(800, "01n")
	if got := conditions(night); got != "\U000f0594" {
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
