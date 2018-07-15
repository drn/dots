package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/util"
)

// Hammerspoon - Installs Hammerspoon configuration
func Hammerspoon() {
  log.Action("Install Hammerspoon")
  link("lib/hammerspoon", ".hammerspoon")
  log.Info("Reloading Hammerspoon")
  util.Osascript(
    "tell application \"%s\" to execute lua code \"%s\"",
    "Hammerspoon",
    "hs.reload()",
  )
}
