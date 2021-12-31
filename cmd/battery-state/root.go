// Prints the current battery remaining percentage

package main

import (
	"fmt"
	"github.com/drn/dots/cli/run"
	"strings"
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
