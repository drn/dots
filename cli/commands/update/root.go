package update

import (
	"github.com/drn/dots/cli/commands/install"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
	"github.com/drn/dots/cli/run"
	"github.com/drn/dots/cli/tmux"
	"os"
)

// Run - Runs update scripts
func Run() {
	log.Action("Updating dependencies")
	window := tmux.Window()
	tmux.SetWindow("update")

	updateZsh()
	updateBrew()
	rehashRbenv()
	rehashPyenv()
	install.Call("vim")

	tmux.SetWindow(window)
	log.Info("Update complete!")
}

func setWindow(name string) {
	if name == "" {
		return
	}
	run.Capture("tmux rename-window %s", name)
}

func updateZsh() {
	log.Info("Updating ZSH plugins")
	run.Verbose(
		"antibody bundle < \"%s\" > ~/.bundles",
		path.FromDots("zsh/bundles"),
	)
}

func updateBrew() {
	log.Info("Updating Homebrew and outdated packages")
	run.Verbose("brew update")
	run.Verbose("brew upgrade")
}

func rehashRbenv() {
	log.Info("Rehashing rbenv binaries")
	os.Remove(path.FromHome(".rbenv/shims/.rbenv-shim"))
	run.Verbose("rbenv rehash")
}

func rehashPyenv() {
	log.Info("Rehashing pyenv binaries")
	os.Remove(path.FromHome(".rbenv/shims/.rbenv-shim"))
	run.Verbose("rbenv rehash")
}
