package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/link"
  "github.com/drn/dots/path"
  "github.com/drn/dots/run"
)

var rubyVersion = "2.5.1"

// Ruby - Configures Ruby
func (i Install) Ruby() {
  log.Action("Installing Ruby")
  link.Soft(
    path.FromDots("lib/bin"),
    path.FromHome("bin"),
  )
  log.Info("Ensuring Ruby %s is installed", rubyVersion)
  run.Verbose("eval \"$(rbenv init -)\"")
  run.Verbose("rbenv install %s -s", rubyVersion)
  run.Verbose("rbenv global %s", rubyVersion)
  run.Verbose("gem install bundler")
}
