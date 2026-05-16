package install

import (
	"os"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
	"github.com/drn/dots/pkg/run"
)

// Pi - Installs pi.dev coding agent and configuration
//
// Only models.json is tracked. auth.json (provider API keys) and sessions/
// (per-session state) stay local and out of git.
func Pi() {
	log.Action("Install pi.dev")

	installPi()

	// Always reconcile the config symlink, even if the binary is already
	// installed — re-running `dots install pi` should restore the link if
	// it was removed or replaced.
	agentDir := path.FromHome(".pi/agent")
	if err := os.MkdirAll(agentDir, 0755); err != nil {
		log.Error("Failed to create %s: %s", agentDir, err.Error())
		return
	}

	link.Soft(
		path.FromDots("pi/agent/models.json"),
		path.FromHome(".pi/agent/models.json"),
	)
}

func installPi() {
	if err := run.Silent("which pi"); err == nil {
		log.Info("pi.dev already installed")
		return
	}
	exec("curl -fsSL https://pi.dev/install.sh | sh")
}
