package clean

import (
	"github.com/drn/dots/cli/tmux"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

// Run - Runs update scripts
func Run() {
	log.Action("Cleaning up dependencies")
	winName, winNum := tmux.Window()
	tmux.SetWindow("clean", winNum)

	log.Info("Cleaning Homebrew dependencies")
	run.Verbose("brew cleanup -s")

	log.Info("Cleaning vim plugins")
	run.Silent("nvim -c \"PlugClean!|q\"")

	tmux.SetWindow(winName, winNum)
	log.Info("Cleaning complete!")
}
