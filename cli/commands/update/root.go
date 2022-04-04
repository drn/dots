package update

import (
	"github.com/drn/dots/cli/commands/clean"
	"github.com/drn/dots/cli/commands/install"
	"github.com/drn/dots/cli/tmux"
	"github.com/drn/dots/pkg/cache"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
	"github.com/drn/dots/pkg/run"
)

// Run - Runs update scripts
func Run() {
	winName, winNum := tmux.Window()
	checkClean()

	tmux.SetWindow("update", winNum)
	log.Action("Updating dependencies")
	updateDots()
	updateZsh()
	updateBrew()
	updateSolargraph()
	reshimAsdf()
	install.Call("vim")

	tmux.SetWindow(winName, winNum)
	log.Info("Update complete!")
}

func setWindow(name string) {
	if name == "" {
		return
	}
	run.Capture("tmux rename-window %s", name)
}

func checkClean() {
	if cache.Warm("dots-clean", 10080) { // 7 days
		return
	}
	clean.Run()
	cache.Touch("dots-clean")
}

func updateDots() {
	log.Info("Updating dots")
	run.Verbose(
		"cd %s; git fetch; git reset --hard origin/master; go install ./...",
		path.Dots(),
	)
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

func updateSolargraph() {
	log.Info("Updating solargraph gem")
	run.Verbose("gem update solargraph")
}

func reshimAsdf() {
	log.Info("Reshiming asdf binaries")
	run.Verbose("asdf reshim")
}
