// Package install contains all environment bootstrapping logic
package install

import (
	"os"

	"github.com/drn/dots/pkg/run"
)

// Install - Struct containing all install commands
type Install struct{}

// Call - Call install command by name
func Call(command string) {
	var i Install
	installers := map[string]func(){
		"agents":      i.Agents,
		"bin":         i.Bin,
		"fonts":       i.Fonts,
		"git":         i.Git,
		"hammerspoon": i.Hammerspoon,
		"home":        i.Home,
		"homebrew":    i.Homebrew,
		"languages":   i.Languages,
		"npm":         i.Npm,
		"osx":         i.Osx,
		"vim":         i.Vim,
		"zsh":         i.Zsh,
	}
	if fn, ok := installers[command]; ok {
		fn()
	}
}

// Verbosely runs a command and fails if the command fails
func exec(command string, args ...interface{}) {
	if err := run.Verbose(command, args...); err != nil {
		os.Exit(1)
	}
}
