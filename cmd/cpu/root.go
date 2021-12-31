package main

import (
	"fmt"
	"github.com/drn/dots/cli/run"
	"math"
	"strconv"
	"strings"
)

func main() {
	info := run.Capture("sysctl -n vm.loadavg")
	info = info[2 : len(info)-2]

	// load averages [1 min, 5 min, 15 min]
	averages := strings.Split(info, " ")
	average, _ := strconv.ParseFloat(averages[0], 64)

	fmt.Printf("%v%%\n", math.Round(average))
}
