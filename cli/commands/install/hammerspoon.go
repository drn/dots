package install

import (
  "github.com/drn/dots/cli/log"
  "github.com/drn/dots/cli/run"
  "github.com/drn/dots/cli/link"
  "github.com/drn/dots/cli/path"
)

// Hammerspoon - Installs Hammerspoon configuration
func (i Install) Hammerspoon() {
  log.Action("Install Hammerspoon")
  link.Soft(
    path.FromDots("hammerspoon"),
    path.FromHome(".hammerspoon"),
  )
  log.Info("Reloading Hammerspoon")
  run.OSA(
    "tell application \"%s\" to execute lua code \"%s\"",
    "Hammerspoon",
    "hs.reload()",
  )
}
