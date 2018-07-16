package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/util"
  "github.com/drn/dots/link"
  "github.com/drn/dots/path"
)

// Hammerspoon - Installs Hammerspoon configuration
func Hammerspoon() {
  log.Action("Install Hammerspoon")
  link.Soft(
    path.FromDots("lib/hammerspoon"),
    path.FromHome(".hammerspoon"),
  )
  log.Info("Reloading Hammerspoon")
  util.Osascript(
    "tell application \"%s\" to execute lua code \"%s\"",
    "Hammerspoon",
    "hs.reload()",
  )
}
