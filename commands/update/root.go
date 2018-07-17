package update

import (
  "os"
  "strings"
  "github.com/drn/dots/log"
  "github.com/drn/dots/path"
  "github.com/drn/dots/util"
  "github.com/drn/dots/commands/install"
)

// Run - Runs update scripts
func Run() {
  log.Action("Updating dependencies")
  window := ""
  if isTmux() {
    window = util.Exec("tmux display-message -p '#W'")
    setWindow("update")
  }
  updateZsh()
  updateBrew()
  rehashRbenv()
  rehashPyenv()
  install.Vim()
  setWindow(window)
  log.Info("Update complete!")
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

func updateZsh() {
  log.Info("Updating ZSH plugins")
  util.Run(
    "antibody bundle < \"%s\" > ~/.bundles",
    path.FromDots("zsh/bundles"),
  )
}

func updateBrew() {
  log.Info("Updating Homebrew and outdated packages")
  util.Run("brew update")
  util.Run("brew upgrade")
}

func rehashRbenv() {
  log.Info("Rehashing rbenv binaries")
  os.Remove(path.FromHome(".rbenv/shims/.rbenv-shim"))
  util.Run("rbenv rehash")
}

func rehashPyenv() {
  log.Info("Rehashing pyenv binaries")
  os.Remove(path.FromHome(".rbenv/shims/.rbenv-shim"))
  util.Run("rbenv rehash")
}
