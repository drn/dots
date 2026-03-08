package install

import (
	"encoding/json"
	"os"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// ttsInstructions is the global CLAUDE.md content for TTS notifications
const ttsInstructions = `## TTS Notifications

**ALWAYS speak aloud when completing ANY task or waiting for user input.** This is mandatory.

**First, check if on a call:**
` + "```bash" + `
mic-check  # returns "active" (exit 0) or "inactive" (exit 1)
` + "```" + `
If mic is **active**, skip TTS entirely — user is in a call. Do not speak.

When mic is inactive, use TTS:
` + "```" + `
Tool: mcp__tts__openai_tts
Speed: 1.4
Words: 2-4 max (e.g., "Done", "Updated config", "Need input")
` + "```" + `

Do this BEFORE moving to the next task. If you forget, you're not following instructions.
`

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

	// Codex: ensure ~/.agents exists and symlink skills
	agentsDir := path.FromHome(".agents")
	if _, err := os.Stat(agentsDir); os.IsNotExist(err) {
		if err := os.MkdirAll(agentsDir, 0755); err != nil {
			log.Error("Failed to create ~/.agents directory: %s", err.Error())
			return
		}
	}
	link.Soft(skillsSource, path.FromHome(".agents/skills"))

	// Install global CLAUDE.md with TTS instructions
	installClaudeMD()

	// Install TTS MCP server in global settings
	installTTSServer()
}

// installClaudeMD writes ~/.claude/CLAUDE.md with TTS instructions
func installClaudeMD() {
	target := path.FromHome(".claude/CLAUDE.md")
	if err := os.WriteFile(target, []byte(ttsInstructions), 0644); err != nil {
		log.Error("Failed to write ~/.claude/CLAUDE.md: %s", err.Error())
		return
	}
	log.Info("Installed ~/.claude/CLAUDE.md")
}

// installTTSServer adds the TTS MCP server to ~/.claude/settings.json
func installTTSServer() {
	settingsPath := path.FromHome(".claude/settings.json")

	// Read existing settings
	settings := map[string]interface{}{}
	if data, err := os.ReadFile(settingsPath); err == nil {
		if err := json.Unmarshal(data, &settings); err != nil {
			log.Error("Failed to parse ~/.claude/settings.json: %s", err.Error())
			return
		}
	}

	// Get or create mcpServers block
	mcpServers, ok := settings["mcpServers"].(map[string]interface{})
	if !ok {
		mcpServers = map[string]interface{}{}
	}

	// Add TTS server (source OPENAI_API_KEY from sys/env)
	mcpServers["tts"] = map[string]interface{}{
		"command": "sh",
		"args": []interface{}{
			"-c",
			"source " + path.FromHome(".dots/sys/env") + " && exec /opt/homebrew/bin/mcp-tts",
		},
		"env": map[string]interface{}{
			"MCP_TTS_SUPPRESS_SPEAKING_OUTPUT": "true",
		},
	}

	settings["mcpServers"] = mcpServers

	// Write back with indentation
	data, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		log.Error("Failed to marshal settings.json: %s", err.Error())
		return
	}

	if err := os.WriteFile(settingsPath, append(data, '\n'), 0644); err != nil {
		log.Error("Failed to write ~/.claude/settings.json: %s", err.Error())
		return
	}
	log.Info("Installed TTS server in ~/.claude/settings.json")
}
