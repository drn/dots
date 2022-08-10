// Prints the current battery remaining percentage
package main

import (
	"fmt"
	"strings"

	"github.com/drn/dots/pkg/run"
)

func main() {
	info := run.Capture("pmset -g ps")
	info = strings.Split(info, "\n")[0]
	if strings.Contains(info, "AC Power") {
		fmt.Println("charging")
	} else {
		fmt.Println("battery")
	}
}
