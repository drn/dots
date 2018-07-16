package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/link"
  "github.com/drn/dots/path"
)

// Git - Installs git configuration
func Git() {
  log.Action("Install Git")
  link.Soft(
    path.FromDots("lib/git/functions"),
    path.FromHome(".git-extensions"),
  )
}
