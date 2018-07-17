package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/util"
  "github.com/drn/dots/path"
)

// Homebrew - Installs Homebrew dependencies
func Homebrew() {
  log.Action("Installing Homebrew dependencies")
  util.Run("brew bundle --file=%s", path.FromDots("lib/Brewfile"))
  util.Run("brew services start mysql@5.6")
  util.Run("brew services start postgresql")
}
