// Package center outputs configuration for the tmux-status center section
package center

import (
	"fmt"

	col "github.com/drn/dots/cmd/tmux-status/color"
	sep "github.com/drn/dots/cmd/tmux-status/separator"
)

// Other - inactive window status
func Other() {
	fmt.Printf(
		"%s%s%s #I #W %s%s\n",
		col.C3_2,
		sep.R1,
		col.C2,
		col.C2_3,
		sep.R1,
	)
}

// Current - active window status
func Current() {
	fmt.Printf(
		"%s%s%s #I #W %s%s\n",
		col.C3_1,
		sep.R1,
		col.C1,
		col.C1_3,
		sep.R1,
	)
}
