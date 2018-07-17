package cleanup

import (
  "github.com/drn/dots/is"
  "github.com/drn/dots/log"
  "github.com/drn/dots/run"
)

// Run - Runs update scripts
func Run() {
  log.Action("Cleaning up dependencies")
  window := ""
  if is.Tmux() {
    window = run.Capture("tmux display-message -p '#W'")
    setWindow("cleanup")
  }

  log.Info("Cleaning up Homebrew dependencies")
  run.Verbose("brew cleanup -s")
  run.Verbose("brew cask cleanup")

  log.Info("Cleaning up vim plugins")
  run.Silent("nvim -c \"PlugClean|q\"")

  setWindow(window)
  log.Info("Cleaning complete!")
}

func setWindow(name string) {
  if name == "" { return }
  run.Capture("tmux rename-window %s", name)
}
