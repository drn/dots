package install

import (
  "github.com/drn/dots/log"
)

// Bin - Symlinks ~/bin directory
func Bin() {
  log.Action("Install Bin")
  link("lib/bin", "bin")
}
