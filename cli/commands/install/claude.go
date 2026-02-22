package install

import (
	"os"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Claude - Installs Claude configuration
func (i Install) Claude() {
	log.Action("Install Claude")

	// Ensure ~/.claude directory exists
	claudeDir := path.FromHome(".claude")
	if _, err := os.Stat(claudeDir); os.IsNotExist(err) {
		err := os.MkdirAll(claudeDir, 0755)
		if err != nil {
			log.Error("Failed to create ~/.claude directory: %s", err.Error())
			return
		}
	}

	link.Soft(
		path.FromDots("claude/commands"),
		path.FromHome(".claude/commands"),
	)

	link.Soft(
		path.FromDots("claude/skills"),
		path.FromHome(".claude/skills"),
	)
}
