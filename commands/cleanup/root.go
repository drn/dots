package cleanup

import (
  "os"
  "strings"
  "github.com/drn/dots/log"
  "github.com/drn/dots/util"
)

// Run - Runs update scripts
func Run() {
  log.Action("Cleaning up dependencies")
  window := ""
  if isTmux() {
    window = util.Exec("tmux display-message -p '#W'")
    setWindow("cleanup")
  }

  log.Info("Cleaning up Homebrew dependencies")
  util.Run("brew cleanup -s")
  util.Run("brew cask cleanup")

  log.Info("Cleaning up vim plugins")
  util.RunSilent("nvim -c \"PlugClean|q\"")

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
  util.Exec("tmux rename-window %s", name)
}
