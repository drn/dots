package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/util"
)

// Npm - Installs global npm packages
func Npm () {
  log.Action("Install npm packages")
  npm([]string{
    "json-diff",
    "semver",
    "bower",
    "grunt-cli",
    "underscore-cli",
    "diff-so-fancy",
    "git-standup",
    "eslint",
    "vtop",
    "neovim",
    "fkill-cli",
  })
}

func npm(packages []string) {
  for _, pack := range packages {
    log.Info("Ensuring %s is installed and up-to-date", pack)
    util.Run("npm install -g %s", pack)
  }
}
