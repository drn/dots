package install

import (
	"encoding/json"
	"os"

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

	// Install TTS MCP server in global settings
	installTTSServer()
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
