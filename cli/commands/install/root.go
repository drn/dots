// Package install contains all environment bootstrapping logic
package install

import (
	"os"

	"github.com/drn/dots/pkg/run"
)

// Call - Call install command by name
func Call(command string) {
	installers := map[string]func(){
		"agents":      Agents,
		"bin":         Bin,
		"fonts":       Fonts,
		"git":         Git,
		"hammerspoon": Hammerspoon,
		"home":        Home,
		"homebrew":    Homebrew,
		"languages":   Languages,
		"npm":         Npm,
		"osx":         Osx,
		"vim":         Vim,
		"zsh":         Zsh,
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
