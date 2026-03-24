package install

import (
	"encoding/json"
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

	// Register skill usage tracking hook
	registerSkillTrackingHook()
}

// registerSkillTrackingHook adds a PreToolUse hook for the Skill tool to
// ~/.claude/settings.json so that skill invocations are logged.
func registerSkillTrackingHook() {
	settingsPath := path.FromHome(".claude/settings.json")

	// Read existing settings
	data, err := os.ReadFile(settingsPath)
	if err != nil {
		if os.IsNotExist(err) {
			data = []byte("{}")
		} else {
			log.Warning("Failed to read settings: %s", err.Error())
			return
		}
	}

	var settings map[string]any
	if err := json.Unmarshal(data, &settings); err != nil {
		log.Warning("Failed to parse settings: %s", err.Error())
		return
	}

	// Build the hook entry
	hookCmd := "bash " + path.FromDots("agents/hooks/track-skill-use.sh")
	hookEntry := map[string]any{
		"matcher": "Skill",
		"hooks": []any{
			map[string]any{
				"type":    "command",
				"command": hookCmd,
			},
		},
	}

	// Get or create hooks.PreToolUse array
	hooks, _ := settings["hooks"].(map[string]any)
	if hooks == nil {
		hooks = make(map[string]any)
	}

	preToolUse, _ := hooks["PreToolUse"].([]any)

	// Check if a Skill matcher already exists
	for _, existing := range preToolUse {
		if entry, ok := existing.(map[string]any); ok {
			if entry["matcher"] == "Skill" {
				return // already registered
			}
		}
	}

	preToolUse = append(preToolUse, hookEntry)
	hooks["PreToolUse"] = preToolUse
	settings["hooks"] = hooks

	// Write back
	out, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		log.Warning("Failed to marshal settings: %s", err.Error())
		return
	}
	out = append(out, '\n')

	if err := os.WriteFile(settingsPath, out, 0644); err != nil {
		log.Warning("Failed to write settings: %s", err.Error())
		return
	}

	log.Success("Registered skill usage tracking hook")
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
