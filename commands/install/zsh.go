package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/run"
  "github.com/drn/dots/path"
  "github.com/drn/dots/util"
)

// Zsh - Installs ZSH configuration
func Zsh() {
  log.Action("Install Zsh")

  // delete /etc/zprofile - added by os x 10.11
  // path_helper conflicts - http://www.zsh.org/mla/users/2015/msg00727.html
  log.Info("Ensuring /etc/zprofile is removed")
  if util.IsFileExists("/etc/zprofile") {
    run.Verbose("sudo rm -f /etc/zprofile")
  }

  // ensure antibody is installed
  log.Info("Ensuring antibody is installed")
  if util.IsCommand("brew") && !util.IsCommand("antibody") {
    log.Info("Installing antibody...")
    run.Verbose("brew install getantibody/tap/antibody 2>/dev/null")
  }

  // run antibody bundle
  log.Info("Bundling antibody dependencies")
  run.Verbose(
    "antibody bundle < \"%s\" > ~/.bundles",
    path.FromDots("zsh/bundles"),
  )
}
