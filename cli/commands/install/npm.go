package install

import (
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/run"
	"strings"
)

// Npm - Installs global npm packages
func (i Install) Npm() {
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
		"fx",
		"fast-cli",
		"catj",
	})
}

func npm(packages []string) {
	installed := run.Capture("npm list --global --parseable --depth=0")

	for _, pack := range packages {
		log.Info("Ensuring %s is installed", pack)
		if !strings.Contains(installed, pack) {
			run.Verbose("npm install -g %s", pack)
		}
	}
}
