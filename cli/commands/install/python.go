// Neovim setup logic from
// https://github.com/zchee/deoplete-jedi/wiki/Setting-up-Python-for-Neovim

package install

import (
	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
	"github.com/drn/dots/cli/run"
)

// Python - Configures Python
func (i Install) Python() {
	log.Action("Installing Python")

	log.Info("Installing python versions")
	run.Verbose("pyenv install 2.7.18 -s")
	run.Verbose("pyenv install 3.9.1 -s")
	log.Info("Creating pyenv virtualenvs")
	run.Verbose("pyenv virtualenv 2.7.18 neovim2 || true")
	run.Verbose("pyenv virtualenv 3.9.1 neovim3 || true")

	log.Info("Installing python2 neovim dependencies")
	neovim2 := "eval \"$(pyenv init -)\" && pyenv shell neovim2"
	run.Verbose(
		"%s && %s && %s",
		neovim2,
		"pyenv exec pip install --upgrade pip pynvim",
		"pyenv which python",
	)

	log.Info("Installing python3 neovim dependencies")
	neovim3 := "eval \"$(pyenv init -)\" && pyenv shell neovim3"
	run.Verbose(
		"%s && %s && %s",
		neovim3,
		"pyenv exec pip install --upgrade pip pynvim flake8",
		"pyenv which python",
	)

	log.Info("Linking neovim3 flake8 python linter")
	link.Soft(
		run.Capture("%s && pyenv which flake8", neovim3),
		path.FromHome("bin/flake8"),
	)

	log.Info("Installing pip dependencies")
	run.Verbose("pip2 install wakatime")
}
