// Package left outputs configuration for the tmux-status left section
package left

import (
	"fmt"

	col "github.com/drn/dots/cmd/tmux-status/color"
	sep "github.com/drn/dots/cmd/tmux-status/separator"
	"github.com/drn/dots/pkg/run"
)

// Position -
type Position struct{}

// Min - 1/3 display
func (pos Position) Min() {
	fmt.Printf(
		"%s %s %s%s%s\n",
		col.C1,
		first(),
		col.C1_3, sep.R1, col.C3,
	)
}

// Med - 2/3 display
func (pos Position) Med() {
	fmt.Printf(
		"%s %s %s%s%s %s %s%s%s\n",
		col.C1,
		first(),
		col.C1_2, sep.R1, col.C2,
		externalIP(),
		col.C2_3, sep.R1, col.C3,
	)
}

// Max - full display
func (pos Position) Max() {
	second := second()
	third := ""
	if second != "Offline" {
		third = externalIP()
	}

	fmt.Printf(
		"%s %s %s%s%s %s %s%s%s %s\n",
		col.C1,
		first(),
		col.C1_2, sep.R1, col.C2,
		second,
		col.C2_3, sep.R1, col.C3,
		third,
	)
}

func first() string {
	return fmt.Sprintf(
		"#S%s%s",
		fmt.Sprintf("#{?window_zoomed_flag, %s \uf848,}", sep.R2),
		fmt.Sprintf("#{?window_marked_flag, %s \uf041,}", sep.R2),
	)
}

func second() string {
	ssid := run.Capture("ssid")
	if ssid == "" {
		return "Offline"
	}
	return fmt.Sprintf("%s %s %s", ssid, sep.R2, localIP())
}

func localIP() string {
	return run.Capture("ip --local en7 || ip --local || echo 127.0.0.1")
}

func externalIP() string {
	externalIP := run.Capture("ip")
	homeIP := run.Capture("ip --home")
	symbol := '\uf7b6' // globe
	if externalIP == homeIP {
		symbol = '\ufccf' // home
	}
	return fmt.Sprintf("%s %c", externalIP, symbol)
}
