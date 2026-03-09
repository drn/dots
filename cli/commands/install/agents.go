package install

import (
	"os"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Agents - Installs agent skills and custom agents for Claude Code and Codex
func Agents() {
	log.Action("Install Agents")

	skillsSource := path.FromDots("agents/skills")
	customSource := path.FromDots("agents/custom")

	// Claude Code: ensure ~/.claude exists and symlink skills + custom agents
	if !ensureDir(path.FromHome(".claude")) {
		return
	}
	link.Soft(skillsSource, path.FromHome(".claude/skills"))
	link.Soft(customSource, path.FromHome(".claude/agents"))

	// Codex: ensure ~/.agents exists and symlink skills
	if !ensureDir(path.FromHome(".agents")) {
		return
	}
	link.Soft(skillsSource, path.FromHome(".agents/skills"))

	// Symlink global CLAUDE.md
	link.Soft(path.FromDots("agents/AGENTS.md"), path.FromHome(".claude/CLAUDE.md"))
}

func ensureDir(dir string) bool {
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		if err := os.MkdirAll(dir, 0755); err != nil {
			log.Error("Failed to create directory %s: %s", dir, err.Error())
			return false
		}
	}
	return true
}
