package install

import (
	"github.com/drn/dots/cli/log"
)

// Asdf - Configures ASDF
func (i Install) Asdf() {
	log.Action("Installing asdf")
	log.Info("Ensuring asdf is installed")
	exec("brew install asdf")
	exec("asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby || true")
}
