package install

import (
  "github.com/fatih/color"
  "github.com/drn/dots/util"
)

// Zsh - Installs ZSH configuration
func Zsh() {
  // delete /etc/zprofile - added by os x 10.11
  // path_helper conflicts - http://www.zsh.org/mla/users/2015/msg00727.html
  util.Run("sudo rm -f /etc/zprofile")

  // ensure antibody is installed
  if util.IsCommand("brew") && !util.IsCommand("antibody") {
    color.Blue("Installing antibody...")
    util.Run("brew install getantibody/tap/antibody 2>/dev/null")
  }

  // run antibody bundle
  util.Run("antibody bundle < \"$DOTS/zsh/bundles\" > ~/.bundles")
}
