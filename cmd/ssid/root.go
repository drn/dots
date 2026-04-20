// If available, prints out WiFi SSID currently connected to.
// Using the --short option shortens the SSID using the first two words of the
// SSID and limited to a maximum of 12 characters.
//
// On macOS 14+, Location Services permission is required for apps to read the
// current SSID through public APIs. When the primary path returns "<redacted>",
// falls back to parsing the scan record cached by the system configuration
// database, which isn't subject to the same redaction filter.
package main

import (
	"encoding/hex"
	"fmt"
	"os"
	"strings"
	"unicode/utf8"

	"howett.net/plist"

	"github.com/drn/dots/pkg/run"
)

const redacted = "<redacted>"

func main() {
	ssid := currentSSID()
	if ssid == "" {
		os.Exit(0)
	}
	printSSID(ssid)
}

func currentSSID() string {
	s := run.Capture("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'")
	if s != "" && s != redacted {
		return s
	}
	return cachedScanSSID()
}

func cachedScanSSID() string {
	out := run.Capture(`echo "show State:/Network/Interface/en0/AirPort" | scutil | awk '/CachedScanRecord/ {print $4}'`)
	data, err := hex.DecodeString(strings.TrimPrefix(out, "0x"))
	if err != nil {
		return ""
	}
	return extractSSID(data)
}

func extractSSID(data []byte) string {
	var archive struct {
		Objects []interface{} `plist:"$objects"`
	}
	if _, err := plist.Unmarshal(data, &archive); err != nil {
		return ""
	}

	keyIdx := -1
	for i, obj := range archive.Objects {
		if s, ok := obj.(string); ok && s == "SSID_STR" {
			keyIdx = i
			break
		}
	}
	if keyIdx < 0 {
		return ""
	}

	for _, obj := range archive.Objects {
		d, ok := obj.(map[string]interface{})
		if !ok {
			continue
		}
		keys, _ := d["NS.keys"].([]interface{})
		objs, _ := d["NS.objects"].([]interface{})
		for i, k := range keys {
			uid, ok := k.(plist.UID)
			if !ok || int(uid) != keyIdx || i >= len(objs) {
				continue
			}
			valUID, ok := objs[i].(plist.UID)
			if !ok || int(valUID) >= len(archive.Objects) {
				continue
			}
			if s, ok := archive.Objects[int(valUID)].(string); ok && s != "$null" && s != "" {
				return s
			}
		}
	}
	return ""
}

func printSSID(ssid string) {
	if len(os.Args) > 1 && os.Args[1] == "--short" {
		parts := strings.Split(ssid, " ")
		if len(parts) > 2 {
			ssid = fmt.Sprintf("%s…", strings.Join(parts[:2], " "))
		}
		if utf8.RuneCountInString(ssid) > 12 {
			ssid = fmt.Sprintf("%s…", string([]rune(ssid)[:12]))
		}
	}
	fmt.Println(ssid)
}
