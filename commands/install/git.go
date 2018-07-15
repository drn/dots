package install

import (
  "github.com/fatih/color"
)

// Git - Installs git configuration
func Git() {
  color.Magenta("Install Git")
  link("lib/git/functions", ".git-extensions")
}
