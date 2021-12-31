package install

import (
	"strings"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

// Npm - Installs global npm packages
func (i Install) Npm() {
	log.Action("Install npm packages")
	npm([]string{
		"bower",
		"catj",
		"diff-so-fancy",
		"eslint",
		"fast-cli",
		"fkill-cli",
		"fx",
		"git-standup",
		"grunt-cli",
		"json-diff",
		"neovim",
		"semver",
		"underscore-cli",
		"vtop",
		"yarn",
	})
}

func npm(packages []string) {
	installed := run.Capture("npm list --global --parseable --depth=0")

	for _, pack := range packages {
		log.Info("Ensuring %s is installed", pack)
		if !strings.Contains(installed, pack) {
			exec("npm install -g %s", pack)
		}
	}
}
