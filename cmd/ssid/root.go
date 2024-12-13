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
	info := run.Capture("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'")

	if len(info) == 0 {
		os.Exit(0)
	}

	printSSID(info)
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
