package right

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	col "github.com/drn/dots/cmd/tmux-status/color"
	sep "github.com/drn/dots/cmd/tmux-status/separator"
	"github.com/drn/dots/pkg/run"
)

// Position -
type Position struct{}

var now time.Time

func init() {
	now = time.Now()
}

// Min - 1/3 display
func (pos Position) Min() {
	fmt.Printf(
		"%s%s%s %s \n",
		col.C1_3, sep.L1, col.C1,
		first(),
	)
}

// Med - 2/3 display
func (pos Position) Med() {
	fmt.Printf(
		"%s%s%s %s %s%s%s %s \n",
		col.C2_3, sep.L1, col.C2,
		third(),
		col.C1_2, sep.L1, col.C1,
		first(),
	)
}

// Max - full display
func (pos Position) Max() {
	fmt.Printf(
		"%s %s %s%s%s %s %s%s%s %s \n",
		col.C3,
		third(),
		col.C2_3, sep.L1, col.C2,
		second(),
		col.C1_2, sep.L1, col.C1,
		first(),
	)
}

func first() string {
	return now.Format("3:04pm")
}

func second() string {
	return fmt.Sprintf(
		"%s %s %s",
		now.Format("Mon 2"),
		sep.L2,
		now.Format("Jan 2006"),
	)
}

func third() string {
	return fmt.Sprintf(
		"%sc %sm %sb",
		run.Capture("cpu"),
		run.Capture("memory"),
		battery(),
	)
}

func battery() string {
	info := strings.Split(run.Capture("pmset -g ps"), "\n")

	status := "battery"
	if strings.Contains(info[0], "AC Power") {
		status = "charging"
	}

	// extract percent from pmset metadata
	percentString := strings.Fields(info[1])[2]
	// strip trailing %;
	percentString = percentString[:len(percentString)-2]
	percent, _ := strconv.Atoi(percentString)

	color := ""
	switch {
	case percent <= 20 && status == "charging":
		color = col.C3Bc20
	case percent <= 20 && status == "battery":
		color = col.C3Bb20
	case percent <= 10 && status == "charging":
		color = col.C3Bc10
	case percent <= 10 && status == "battery":
		color = col.C3Bb10
	}

	return fmt.Sprintf("%s%d%%", color, percent)
}