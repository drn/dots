// Outputs tmux statusline configurations for the given input position & screen
// width
package main

import (
	"os"
	"strconv"

	"github.com/drn/dots/cmd/tmux-status/center"
	"github.com/drn/dots/cmd/tmux-status/left"
	"github.com/drn/dots/cmd/tmux-status/right"
	"github.com/drn/dots/pkg/log"
)

var side string
var width int

// Position -
type Position interface {
	Min()
	Med()
	Max()
}

func main() {
	if len(os.Args) < 2 {
		invalidUsage()
	}

	side = os.Args[1]
	switch side {
	case "center":
		center.Other()
	case "center-current":
		center.Current()
	case "left", "right":
		sides()
	default:
		invalidUsage()
	}
}

func sides() {
	if len(os.Args) < 3 {
		invalidUsage()
	}

	width, err := strconv.Atoi(os.Args[2])
	if err != nil {
		invalidUsage()
	}

	var position Position
	switch side {
	case "left":
		position = left.Position{}
	case "right":
		position = right.Position{}
	default:
	}

	switch {
	case width < 90:
		position.Min()
	case width < 150:
		position.Med()
	default:
		position.Max()
	}
}

func invalidUsage() {
	log.Error("Usage: tmux-status left|right|center|center-current [width]")
	os.Exit(1)
}
