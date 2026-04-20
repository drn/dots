package main

import (
	"bytes"
	"testing"

	"howett.net/plist"
)

func TestExtractSSID(t *testing.T) {
	data := synthBplist(t, "Home WiFi")
	if got := extractSSID(data); got != "Home WiFi" {
		t.Errorf("extractSSID = %q, want %q", got, "Home WiFi")
	}
}

func TestExtractSSIDMissing(t *testing.T) {
	archive := map[string]interface{}{
		"$archiver": "NSKeyedArchiver",
		"$version":  uint64(100000),
		"$top":      map[string]interface{}{"root": plist.UID(1)},
		"$objects": []interface{}{
			"$null",
			map[string]interface{}{
				"NS.keys":    []interface{}{plist.UID(2)},
				"NS.objects": []interface{}{plist.UID(3)},
			},
			"OTHER_KEY",
			"value",
		},
	}
	data := encode(t, archive)
	if got := extractSSID(data); got != "" {
		t.Errorf("extractSSID on missing key = %q, want empty", got)
	}
}

func TestExtractSSIDInvalid(t *testing.T) {
	if got := extractSSID([]byte("not a plist")); got != "" {
		t.Errorf("extractSSID on garbage = %q, want empty", got)
	}
}

func TestPickSSID(t *testing.T) {
	cases := []struct {
		name             string
		primary, fallbk  string
		want             string
	}{
		{"primary wins", "MyNet", "Fallback", "MyNet"},
		{"empty primary falls back", "", "Fallback", "Fallback"},
		{"redacted primary falls back", "<redacted>", "Fallback", "Fallback"},
		{"both empty", "", "", ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := pickSSID(func() string { return tc.primary }, func() string { return tc.fallbk })
			if got != tc.want {
				t.Errorf("pickSSID(%q, %q) = %q, want %q", tc.primary, tc.fallbk, got, tc.want)
			}
		})
	}
}

func synthBplist(t *testing.T, ssid string) []byte {
	t.Helper()
	archive := map[string]interface{}{
		"$archiver": "NSKeyedArchiver",
		"$version":  uint64(100000),
		"$top":      map[string]interface{}{"root": plist.UID(1)},
		"$objects": []interface{}{
			"$null",
			map[string]interface{}{
				"NS.keys":    []interface{}{plist.UID(2)},
				"NS.objects": []interface{}{plist.UID(3)},
			},
			"SSID_STR",
			ssid,
		},
	}
	return encode(t, archive)
}

func encode(t *testing.T, v interface{}) []byte {
	t.Helper()
	buf := &bytes.Buffer{}
	enc := plist.NewBinaryEncoder(buf)
	if err := enc.Encode(v); err != nil {
		t.Fatalf("encode: %v", err)
	}
	return buf.Bytes()
}
