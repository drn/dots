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
	third := string('\U000f05aa')
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
		fmt.Sprintf("#{?window_zoomed_flag, %s \U000f0349,}", sep.R2),
		fmt.Sprintf("#{?window_marked_flag, %s \uf041,}", sep.R2),
	)
}

func second() string {
	ssid := run.Capture("ssid --short")
	if ssid != "" {
		return fmt.Sprintf("%s %s %s", ssid, sep.R2, localIP())
	}
	if ip := localIP(); ip != "127.0.0.1" {
		return fmt.Sprintf("Ethernet %s %s", sep.R2, ip)
	}
	return "Offline"
}

func localIP() string {
	return run.Capture("ip --local $(route -n get default | awk '/interface:/{print $2}') || echo 127.0.0.1")
}

func externalIP() string {
	externalIP := run.Capture("ip")
	if externalIP == "" {
		return string('\U000f05aa')
	}
	homeIP := run.Capture("ip --home")
	if homeIP == "" {
		return string('\U000f05aa')
	}
	symbol := '\U000f02b7' // globe
	if externalIP == homeIP {
		symbol = '\U000f07d1' // home
	}
	return fmt.Sprintf("%s %c", externalIP, symbol)
}
