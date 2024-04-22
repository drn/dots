// If available, prints out WiFi SSID currently connected to.
package main

import (
	"fmt"
	"os"
	"strings"

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

			fmt.Println(ssid)

			os.Exit(0)
		}
	}
}
