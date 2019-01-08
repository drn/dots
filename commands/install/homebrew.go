package install

import (
  "os"
  "github.com/drn/dots/log"
  "github.com/drn/dots/run"
  "github.com/drn/dots/path"
)

// Homebrew - Installs Homebrew dependencies
func (i Install) Homebrew() {
  log.Action("Installing Homebrew dependencies")
  run.Verbose("brew bundle --file=%s", path.FromDots("lib/Brewfile"))
  run.Verbose("brew services start mysql@5.7")
  run.Verbose("brew services start postgresql")
  log.Info("Ensuring ~/.z exists")
  os.OpenFile(path.FromHome("Desktop/z"), os.O_RDONLY|os.O_CREATE, 0666)
}
