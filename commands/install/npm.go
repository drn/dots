package install

import (
  "strings"
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
  installed := util.Exec("npm list --global --parseable --depth=0")

  for _, pack := range packages {
    log.Info("Ensuring %s is installed", pack)
    if !strings.Contains(installed, pack) {
      util.Run("npm install -g %s", pack)
    }
  }
}
