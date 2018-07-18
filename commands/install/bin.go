package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/link"
  "github.com/drn/dots/path"
)

// Bin - Symlinks ~/bin directory
func (i Install) Bin() {
  log.Action("Install Bin")
  link.Soft(
    path.FromDots("lib/bin"),
    path.FromHome("bin"),
  )
}
