package install

import (
	"github.com/drn/dots/cli/is"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
	"github.com/drn/dots/cli/run"
)

// Zsh - Installs ZSH configuration
func (i Install) Zsh() {
	log.Action("Install Zsh")

	// delete /etc/zprofile - added by os x 10.11
	// path_helper conflicts - http://www.zsh.org/mla/users/2015/msg00727.html
	log.Info("Ensuring /etc/zprofile is removed")
	if is.File("/etc/zprofile") {
		run.Verbose("sudo rm -f /etc/zprofile")
	}

	// ensure antibody is installed
	log.Info("Ensuring antibody is installed")
	if is.Command("brew") && !is.Command("antibody") {
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
