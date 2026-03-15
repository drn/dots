// Outputs the current CPU load average percentage
package main

import (
	"fmt"
	"math"
	"strconv"
	"strings"

	"github.com/drn/dots/pkg/run"
)

func main() {
	info := run.Capture("sysctl -n vm.loadavg")
	if len(info) < 4 {
		fmt.Println("0%")
		return
	}
	info = info[2 : len(info)-2]

	averages := strings.Split(info, " ")
	if len(averages) == 0 {
		fmt.Println("0%")
		return
	}
	average, err := strconv.ParseFloat(averages[0], 64)
	if err != nil {
		fmt.Println("0%")
		return
	}

	fmt.Printf("%v%%\n", math.Round(average))
}
