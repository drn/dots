package cleanup

import (
  "os"
  "strings"
  "github.com/drn/dots/log"
  "github.com/drn/dots/run"
)

// Run - Runs update scripts
func Run() {
  log.Action("Cleaning up dependencies")
  window := ""
  if isTmux() {
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

func isTmux() bool {
  if !strings.Contains(os.Getenv("TERM"), "screen") { return false }
  if os.Getenv("TMUX") == "" { return false }
  return true
}

func setWindow(name string) {
  if name == "" { return }
  run.Capture("tmux rename-window %s", name)
}
