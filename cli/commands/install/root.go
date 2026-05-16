// Package install contains all environment bootstrapping logic
package install

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
	"github.com/drn/dots/pkg/run"
)

// Component describes an installable component
type Component struct {
	Name        string
	Description string
	Alias       string
	Fn          func()
}

// Components returns the ordered list of installable components.
// This is the single source of truth for the component registry.
func Components() []Component {
	return []Component{
		{"bin", "Installs ~/bin/* commands", "", Bin},
		{"git", "Installs git extensions", "", Git},
		{"home", "Installs ~/.* config files", "", Home},
		{"zsh", "Installs zsh config files", "", Zsh},
		{"fonts", "Installs fonts", "", Fonts},
		{"homebrew", "Installs Homebrew dependencies", "brew", Homebrew},
		{"npm", "Installs npm packages", "", Npm},
		{"languages", "Installs asdf & languages", "", Languages},
		{"vim", "Installs vim config", "", Vim},
		{"hammerspoon", "Installs hammerspoon configuration", "hs", Hammerspoon},
		{"tools", "Installs dev tools (Devbox, Claude Code, Codex)", "", Tools},
		{"osx", "Installs OSX configuration", "", Osx},
		{"agents", "Installs agent skills (Claude Code + Codex)", "", Agents},
	}
}

// Call - Call install command by name
func Call(command string) {
	for _, c := range Components() {
		if c.Name == command {
			c.Fn()
			return
		}
	}
}

// Verbosely runs a command and fails if the command fails
func exec(command string, args ...interface{}) {
	if err := run.Verbose(command, args...); err != nil {
		os.Exit(1)
	}
}

// linkDirEntries reads each entry under dots/<sourceDir> and links it into
// ~/<targetFmt> (a format string with one %s placeholder receiving the entry
// name). linkFn picks soft vs. hard.
func linkDirEntries(sourceDir, targetFmt string, linkFn func(from, to string)) {
	files, err := os.ReadDir(path.FromDots(sourceDir))
	if err != nil {
		log.Warning("Failed to read %s directory: %s", sourceDir, err.Error())
		return
	}
	for _, file := range files {
		linkFn(
			path.FromDots(sourceDir+"/%s", file.Name()),
			path.FromHome(targetFmt, file.Name()),
		)
	}
}
