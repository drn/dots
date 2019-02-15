// If available, prints out WiFi SSID currently connected to.

package main

import (
	"fmt"
	"github.com/drn/dots/cli/run"
	"os"
	"strings"
)

func main() {
	info := run.Capture("airport -I")

	if strings.Contains(info, "AirPort: Off") {
		fmt.Println("[ disabled ]")
		os.Exit(0)
	}

	lines := strings.Split(info, "\n")

	for _, line := range lines {
		if strings.Contains(line, " SSID: ") {

			ssid := strings.Replace(line, " SSID: ", "", 1)
			ssid = strings.TrimSpace(ssid)

			fmt.Println(ssid)

			os.Exit(0)
		}
	}
}
