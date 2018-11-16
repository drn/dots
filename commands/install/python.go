// Neovim setup logic from
// https://github.com/zchee/deoplete-jedi/wiki/Setting-up-Python-for-Neovim

package install

import (
  "github.com/drn/dots/log"
  "github.com/drn/dots/link"
  "github.com/drn/dots/path"
  "github.com/drn/dots/run"
)

// Python - Configures Python
func (i Install) Python() {
  log.Action("Installing Python")

  log.Info("Configuring neovim python dependencies")
  run.Verbose("eval \"$(pyenv init -)\"")
  run.Verbose("eval \"$(pyenv virtualenv-init -)\"")

  log.Info("Installing python versions")
  run.Verbose("pyenv install 2.7.11 -s")
  run.Verbose("pyenv install 3.4.4 -s")
  log.Info("Creating pyenv virtualenvs")
  run.Verbose("pyenv virtualenv 2.7.11 neovim2 || true")
  run.Verbose("pyenv virtualenv 3.4.4 neovim3 || true")

  log.Info("Installing python2 neovim dependencies")
  run.Verbose("pyenv activate neovim2")
  run.Verbose("pip install --upgrade pip")
  run.Verbose("pip install --upgrade neovim")
  run.Verbose("pyenv which python")

  log.Info("Installing python3 neovim dependencies")
  run.Verbose("pyenv activate neovim3")
  run.Verbose("pip install --upgrade pip")
  run.Verbose("pip install --upgrade neovim")
  run.Verbose("pyenv which python")

  log.Info("Installing flake8 python linter")
  run.Verbose("pip install --upgrade flake8")
  link.Soft(
    run.Capture("pyenv which flake8"),
    path.FromHome("bin/flake8"),
  )

  log.Info("Deactivating pyenv")
  run.Verbose("pyenv deactivate")

  log.Info("Installing pip dependencies")
  run.Verbose("pip2 install wakatime")
}
