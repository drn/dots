package install

import (
  "github.com/drn/dots/util"
)

// Hammerspoon - Installs Hammerspoon configuration
func Hammerspoon() {
  link("lib/hammerspoon", ".hammerspoon")
  util.Osascript(
    "tell application \"%s\" to execute lua code \"%s\"",
    "Hammerspoon",
    "hs.reload()",
  )
}
