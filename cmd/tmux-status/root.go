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
	if !processArgs() {
		log.Error("Usage: tmux-status [left/right/center/center-current] [width]")
		os.Exit(1)
	}

	switch side {
	case "center":
		center.Other()
	case "center-current":
		center.Current()
	default:
		sides()
	}
}

func processArgs() bool {
	if len(os.Args) != 3 {
		return false
	}

	side = os.Args[1]
	switch side {
	case "left":
	case "right":
	case "center":
	case "center-current":
	default:
		return false
	}

	var err error
	width, err = strconv.Atoi(os.Args[2])
	if err != nil {
		return false
	}

	return true
}

func sides() {
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
	case width < 121:
		position.Med()
	default:
		position.Max()
	}
}
