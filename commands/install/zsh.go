package install

import (
  "github.com/fatih/color"
  "github.com/drn/dots/util"
)

// Zsh - Installs ZSH configuration
func Zsh() {
  color.Magenta("Install Zsh")

  // delete /etc/zprofile - added by os x 10.11
  // path_helper conflicts - http://www.zsh.org/mla/users/2015/msg00727.html
  color.Blue("Ensuring /etc/zprofile is removed")
  if util.IsFileExists("/etc/zprofile") {
    util.Run("sudo rm -f /etc/zprofile")
  }

  // ensure antibody is installed
  color.Blue("Ensuring antibody is installed")
  if util.IsCommand("brew") && !util.IsCommand("antibody") {
    color.Blue("Installing antibody...")
    util.Run("brew install getantibody/tap/antibody 2>/dev/null")
  }

  // run antibody bundle
  color.Blue("Bundling antibody dependencies")
  util.Run("antibody bundle < \"$DOTS/zsh/bundles\" > ~/.bundles")
}
