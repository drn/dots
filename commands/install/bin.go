package install

import (
  "github.com/fatih/color"
)

// Bin - Symlinks ~/bin directory
func Bin() {
  color.Magenta("Install Bin")
  link("lib/bin", "bin")
}
