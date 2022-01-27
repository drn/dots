package clean

import (
	"github.com/drn/dots/cli/tmux"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

// Run - Runs update scripts
func Run() {
	log.Action("Cleaning up dependencies")
	window := tmux.Window()
	tmux.SetWindow("clean")

	log.Info("Cleaning Homebrew dependencies")
	run.Verbose("brew cleanup -s")

	log.Info("Cleaning vim plugins")
	run.Silent("nvim -c \"PlugClean!|q\"")

	tmux.SetWindow(window)
	log.Info("Cleaning complete!")
}