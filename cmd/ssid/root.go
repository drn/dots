// If available, prints out WiFi SSID currently connected to.
// Using the --ssid option shortens the SSID using the first two words of the
// SSID and limited to a maximum of 12 characters
package main

import (
	"fmt"
	"os"
	"strings"
	"unicode/utf8"

	"github.com/drn/dots/pkg/run"
)

func main() {
	info := run.Capture("networksetup -getairportnetwork en0")

	if strings.Contains(info, "Wi-Fi power is currently off") {
		os.Exit(0)
	}

	lines := strings.Split(info, "\n")

	for _, line := range lines {
		if strings.Contains(line, "Current Wi-Fi Network: ") {

			ssid := strings.Replace(line, "Current Wi-Fi Network: ", "", 1)
			ssid = strings.TrimSpace(ssid)

			printSSID(ssid)

			os.Exit(0)
		}
	}
}

func printSSID(ssid string) {
	if len(os.Args) > 1 && os.Args[1] == "--short" {
		parts := strings.Split(ssid, " ")
		if len(parts) > 2 {
			ssid = fmt.Sprintf("%s…", strings.Join(parts[:2], " "))
		}
		if utf8.RuneCountInString(ssid) > 12 {
			ssid = fmt.Sprintf("%s…", ssid[:12])
		}
	}
	fmt.Println(ssid)
}
