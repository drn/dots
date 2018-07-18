package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/run"
  "github.com/drn/dots/link"
  "github.com/drn/dots/path"
)

// Hammerspoon - Installs Hammerspoon configuration
func (i Install) Hammerspoon() {
  log.Action("Install Hammerspoon")
  link.Soft(
    path.FromDots("lib/hammerspoon"),
    path.FromHome(".hammerspoon"),
  )
  log.Info("Reloading Hammerspoon")
  run.OSA(
    "tell application \"%s\" to execute lua code \"%s\"",
    "Hammerspoon",
    "hs.reload()",
  )
}
