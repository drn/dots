// Package tmux contains integration with tmux CLI
package tmux

import (
	"os"
	"strconv"
	"strings"

	"github.com/drn/dots/cli/is"
	"github.com/drn/dots/pkg/run"
)

// Window - Returns tmux window name
func Window() (string, int) {
	if !is.Tmux() {
		return "", 0
	}
	data := run.Capture("tmux display-message -p '#W|#I'")
	parts := strings.Split(data, "|")
	if len(parts) != 2 {
		os.Exit(1)
	}
	number, err := strconv.Atoi(parts[1])
	if err != nil {
		os.Exit(1)
	}
	return parts[0], number
}

// SetWindow - Sets tmux window name
func SetWindow(name string, number int) {
	if !is.Tmux() || name == "" {
		return
	}
	run.Capture("tmux rename-window -t %d %s", number, name)
}
