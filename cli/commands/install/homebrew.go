package install

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Homebrew - Installs Homebrew dependencies
func (i Install) Homebrew() {
	log.Action("Installing Homebrew dependencies")
	exec("brew update")
	exec("brew bundle --file=%s", path.FromDots("Brewfile"))
	exec("brew services start mysql@8.0")
	exec("brew services start postgresql@16")
	log.Info("Ensuring ~/.z exists")
	os.OpenFile(path.FromHome("Desktop/z"), os.O_RDONLY|os.O_CREATE, 0666)
}
