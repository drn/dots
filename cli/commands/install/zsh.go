package install

import (
	"github.com/drn/dots/cli/is"
	"github.com/drn/dots/pkg/log"
)

// Zsh - Installs ZSH configuration
func (i Install) Zsh() {
	log.Action("Install Zsh")

	// delete /etc/zprofile - added by os x 10.11
	// path_helper conflicts - http://www.zsh.org/mla/users/2015/msg00727.html
	log.Info("Ensuring /etc/zprofile is removed")
	if is.File("/etc/zprofile") {
		exec("sudo rm -f /etc/zprofile")
	}

	// install tmux tpm
	log.Info("Installing tmux pluin manager")
	exec(
		"git clone %s ~/.tmux/plugins/tpm 2>/dev/null",
		"https://github.com/tmux-plugins/tpm",
	)
	exec("cd ~/.tmux/plugins/tpm; git fetch; git reset --hard origin/master")
}
