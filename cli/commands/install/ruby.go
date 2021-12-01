package install

import (
	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
)

var rubyVersion = "2.5.1"

// Ruby - Configures Ruby
func (i Install) Ruby() {
	log.Action("Installing Ruby")
	link.Soft(
		path.FromDots("bin"),
		path.FromHome("bin"),
	)
	log.Info("Ensuring Ruby %s is installed", rubyVersion)
	exec("eval \"$(rbenv init -)\"")
	exec("rbenv install %s -s", rubyVersion)
	exec("rbenv global %s", rubyVersion)
	exec("gem install bundler")
	exec("gem install neovim")
}
