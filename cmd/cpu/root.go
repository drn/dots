// Outputs the current laptop battery %
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
	info = info[2 : len(info)-2]

	// load averages [1 min, 5 min, 15 min]
	averages := strings.Split(info, " ")
	average, _ := strconv.ParseFloat(averages[0], 64)

	fmt.Printf("%v%%\n", math.Round(average))
}
