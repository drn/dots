package install

import (
	"os"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Codex - Installs Codex configuration
func (i Install) Codex() {
	log.Action("Install Codex")

	// Ensure ~/.agents directory exists
	agentsDir := path.FromHome(".agents")
	if _, err := os.Stat(agentsDir); os.IsNotExist(err) {
		err := os.MkdirAll(agentsDir, 0755)
		if err != nil {
			log.Error("Failed to create ~/.agents directory: %s", err.Error())
			return
		}
	}

	link.Soft(
		path.FromDots("agents/skills"),
		path.FromHome(".agents/skills"),
	)
}
