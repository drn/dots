// Prints the current battery remaining percentage
package main

import (
	"fmt"
	"strings"

	"github.com/drn/dots/pkg/run"
)

func main() {
	lines := strings.Split(run.Capture("pmset -g ps"), "\n")
	if len(lines) < 2 {
		fmt.Println("0%")
		return
	}
	fields := strings.Fields(lines[1])
	if len(fields) < 3 {
		fmt.Println("0%")
		return
	}
	percent := fields[2]
	if len(percent) > 0 {
		percent = strings.TrimRight(percent, ";")
	}
	fmt.Println(percent)
}
