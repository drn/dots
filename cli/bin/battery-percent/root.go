// Prints the current battery remaining percentage

package main

import (
	"fmt"
	"github.com/drn/dots/cli/run"
	"strings"
)

func main() {
	info := run.Capture("pmset -g ps")
	info = strings.Split(info, "\n")[1]
	// extract percent from pmset metadata
	percent := strings.Fields(info)[2]
	// remove trailing ;
	percent = percent[:len(percent)-1]
	fmt.Println(percent)
}
