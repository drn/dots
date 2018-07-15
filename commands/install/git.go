package install

import (
  "github.com/drn/dots/log"
)

// Git - Installs git configuration
func Git() {
  log.Action("Install Git")
  link("lib/git/functions", ".git-extensions")
}
