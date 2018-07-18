package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/run"
  "github.com/drn/dots/path"
)

// Homebrew - Installs Homebrew dependencies
func (i Install) Homebrew() {
  log.Action("Installing Homebrew dependencies")
  run.Verbose("brew bundle --file=%s", path.FromDots("lib/Brewfile"))
  run.Verbose("brew services start mysql@5.6")
  run.Verbose("brew services start postgresql")
}
