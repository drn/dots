package cleanup

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/run"
  "github.com/drn/dots/tmux"
)

// Run - Runs update scripts
func Run() {
  log.Action("Cleaning up dependencies")
  window := tmux.Window()
  tmux.SetWindow("cleanup")

  log.Info("Cleaning up Homebrew dependencies")
  run.Verbose("brew cleanup -s")

  log.Info("Cleaning up vim plugins")
  run.Silent("nvim -c \"PlugClean|q\"")

  tmux.SetWindow(window)
  log.Info("Cleaning complete!")
}
