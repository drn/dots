package install

import (
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

// Tools - Installs dev tools (Devbox, Claude Code, Codex)
func Tools() {
	log.Action("Installing dev tools")
	installDevbox()
	installClaudeCode()
	installCodex()
}

func installDevbox() {
	if err := run.Silent("which devbox"); err == nil {
		log.Info("Devbox already installed")
		return
	}
	exec("curl -fsSL https://get.jetify.com/devbox | bash")
}

func installClaudeCode() {
	if err := run.Silent("which claude"); err == nil {
		log.Info("Claude Code already installed")
		return
	}
	exec("curl -fsSL https://claude.ai/install.sh | bash")
}

func installCodex() {
	if err := run.Silent("which codex"); err == nil {
		log.Info("Codex already installed")
		return
	}
	exec("npm install -g @openai/codex")
}
