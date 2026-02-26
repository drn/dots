package install

import (
	"os"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Agents - Installs agent skills for Claude Code and Codex
func (i Install) Agents() {
	log.Action("Install Agents")

	skillsSource := path.FromDots("agents/skills")

	// Claude Code: ensure ~/.claude exists and symlink skills
	claudeDir := path.FromHome(".claude")
	if _, err := os.Stat(claudeDir); os.IsNotExist(err) {
		if err := os.MkdirAll(claudeDir, 0755); err != nil {
			log.Error("Failed to create ~/.claude directory: %s", err.Error())
			return
		}
	}
	link.Soft(skillsSource, path.FromHome(".claude/skills"))

	// Codex: ensure ~/.agents exists and symlink skills
	agentsDir := path.FromHome(".agents")
	if _, err := os.Stat(agentsDir); os.IsNotExist(err) {
		if err := os.MkdirAll(agentsDir, 0755); err != nil {
			log.Error("Failed to create ~/.agents directory: %s", err.Error())
			return
		}
	}
	link.Soft(skillsSource, path.FromHome(".agents/skills"))
}
