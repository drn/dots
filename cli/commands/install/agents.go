package install

import (
	"encoding/json"
	"os"
	"strings"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Agents - Installs agent skills and custom agents for Claude Code and Codex
func (i Install) Agents() {
	log.Action("Install Agents")

	skillsSource := path.FromDots("agents/skills")
	customSource := path.FromDots("agents/custom")

	// Claude Code: ensure ~/.claude exists and symlink skills + custom agents
	claudeDir := path.FromHome(".claude")
	if _, err := os.Stat(claudeDir); os.IsNotExist(err) {
		if err := os.MkdirAll(claudeDir, 0755); err != nil {
			log.Error("Failed to create ~/.claude directory: %s", err.Error())
			return
		}
	}
	link.Soft(skillsSource, path.FromHome(".claude/skills"))
	link.Soft(customSource, path.FromHome(".claude/agents"))

	// Claude Code: merge hooks into ~/.claude/settings.json
	installHooks()

	// Codex: ensure ~/.agents exists and symlink skills
	agentsDir := path.FromHome(".agents")
	if _, err := os.Stat(agentsDir); os.IsNotExist(err) {
		if err := os.MkdirAll(agentsDir, 0755); err != nil {
			log.Error("Failed to create ~/.agents directory: %s", err.Error())
			return
		}
	}
	link.Soft(skillsSource, path.FromHome(".agents/skills"))

	// Symlink global CLAUDE.md
	claudeMDSource := path.FromDots("agents/AGENTS.md")
	link.Soft(claudeMDSource, path.FromHome(".claude/CLAUDE.md"))
}

// installHooks merges hooks from agents/hooks/hooks.json into ~/.claude/settings.json.
// Hook commands containing $DOTS are resolved to absolute paths at install time.
// Any existing hooks in settings.json are replaced (dots owns the hooks key).
func installHooks() {
	mergeHooksIntoSettings(
		path.FromDots("agents/hooks/hooks.json"),
		path.FromHome(".claude/settings.json"),
		path.Dots(),
	)
}

// mergeHooksIntoSettings reads hooks from hooksPath, resolves $DOTS references
// to dotsDir, and writes them into settingsPath preserving other settings keys.
func mergeHooksIntoSettings(hooksPath, settingsPath, dotsDir string) {
	// Read hooks config
	hooksData, err := os.ReadFile(hooksPath)
	if err != nil {
		log.Warning("No hooks config found at %s", path.Pretty(hooksPath))
		return
	}

	// Resolve $DOTS to absolute path so hooks work regardless of shell env
	resolved := strings.ReplaceAll(string(hooksData), "$DOTS", dotsDir)

	var hooksConfig map[string]interface{}
	if err := json.Unmarshal([]byte(resolved), &hooksConfig); err != nil {
		log.Error("Failed to parse hooks config: %s", err.Error())
		return
	}

	hooks, ok := hooksConfig["hooks"]
	if !ok {
		log.Warning("No 'hooks' key found in hooks config")
		return
	}

	// Read existing settings
	settings := map[string]interface{}{}
	if data, err := os.ReadFile(settingsPath); err == nil {
		if err := json.Unmarshal(data, &settings); err != nil {
			log.Error("Failed to parse existing settings: %s", err.Error())
			return
		}
	}

	// Warn if existing hooks will be replaced
	if _, exists := settings["hooks"]; exists {
		log.Warning("Replacing existing hooks in %s", path.Pretty(settingsPath))
	}

	// Replace hooks key (dots owns this key)
	settings["hooks"] = hooks

	// Write back
	output, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		log.Error("Failed to marshal settings: %s", err.Error())
		return
	}

	if err := os.WriteFile(settingsPath, append(output, '\n'), 0644); err != nil {
		log.Error("Failed to write settings: %s", err.Error())
		return
	}

	log.Info("Merged hooks into %s", path.Pretty(settingsPath))
}
