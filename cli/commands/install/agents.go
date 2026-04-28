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

	// Register Argus KB memory injection on SessionStart
	registerSessionStartMemoryHook()

	// Register Argus KB write logging on PostToolUse
	registerKBChangeTrackingHook()

	// Register status line
	registerStatusLine()
}

// mutateSettings reads ~/.claude/settings.json, applies a mutation function,
// and writes the result back. The mutation function returns true if changes
// were made and should be persisted.
func mutateSettings(mutate func(settings map[string]any) bool) bool {
	settingsPath := path.FromHome(".claude/settings.json")

	fileMode := os.FileMode(0600)
	if info, err := os.Stat(settingsPath); err == nil {
		fileMode = info.Mode()
	}

	data, err := os.ReadFile(settingsPath)
	if err != nil {
		if os.IsNotExist(err) {
			data = []byte("{}")
		} else {
			log.Warning("Failed to read settings: %s", err.Error())
			return false
		}
	}

	var settings map[string]any
	if err := json.Unmarshal(data, &settings); err != nil {
		log.Warning("Failed to parse settings: %s", err.Error())
		return false
	}

	if !mutate(settings) {
		return false
	}

	out, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		log.Warning("Failed to marshal settings: %s", err.Error())
		return false
	}
	out = append(out, '\n')

	if err := os.WriteFile(settingsPath, out, fileMode); err != nil {
		log.Warning("Failed to write settings: %s", err.Error())
		return false
	}

	return true
}

// registerSkillTrackingHook adds a PreToolUse hook for the Skill tool to
// ~/.claude/settings.json so that skill invocations are logged.
func registerSkillTrackingHook() {
	changed := mutateSettings(func(settings map[string]any) bool {
		hookCmd := "bash \"" + path.FromDots("agents/hooks/track-skill-use.sh") + "\""
		hookEntry := map[string]any{
			"matcher": "Skill",
			"hooks": []any{
				map[string]any{
					"type":    "command",
					"command": hookCmd,
				},
			},
		}

		hooks, _ := settings["hooks"].(map[string]any)
		if hooks == nil {
			hooks = make(map[string]any)
		}

		preToolUse, _ := hooks["PreToolUse"].([]any)

		for _, existing := range preToolUse {
			if entry, ok := existing.(map[string]any); ok {
				if entry["matcher"] == "Skill" {
					return false // already registered
				}
			}
		}

		preToolUse = append(preToolUse, hookEntry)
		hooks["PreToolUse"] = preToolUse
		settings["hooks"] = hooks
		return true
	})

	if changed {
		log.Success("Registered skill usage tracking hook")
	}
}

// registerSessionStartMemoryHook adds a SessionStart hook that injects Argus
// KB user prefs and feedback into every Claude Code session via
// hookSpecificOutput.additionalContext.
func registerSessionStartMemoryHook() {
	changed := mutateSettings(func(settings map[string]any) bool {
		hookCmd := "bash \"" + path.FromDots("agents/hooks/session-start-memory.sh") + "\""
		hookEntry := map[string]any{
			"hooks": []any{
				map[string]any{
					"type":    "command",
					"command": hookCmd,
				},
			},
		}

		hooks, _ := settings["hooks"].(map[string]any)
		if hooks == nil {
			hooks = make(map[string]any)
		}

		sessionStart, _ := hooks["SessionStart"].([]any)

		for _, existing := range sessionStart {
			entry, ok := existing.(map[string]any)
			if !ok {
				continue
			}
			inner, ok := entry["hooks"].([]any)
			if !ok {
				continue
			}
			for _, h := range inner {
				cmd, _ := h.(map[string]any)
				if cmd != nil && cmd["command"] == hookCmd {
					return false // already registered
				}
			}
		}

		sessionStart = append(sessionStart, hookEntry)
		hooks["SessionStart"] = sessionStart
		settings["hooks"] = hooks
		return true
	})

	if changed {
		log.Success("Registered Argus KB memory injection hook (SessionStart)")
	}
}

// registerKBChangeTrackingHook adds a PostToolUse hook that appends every
// kb_ingest call to a JSONL change log so /dream can triage incrementally.
func registerKBChangeTrackingHook() {
	changed := mutateSettings(func(settings map[string]any) bool {
		hookCmd := "bash \"" + path.FromDots("agents/hooks/track-kb-change.sh") + "\""
		// Match both legacy and current Argus MCP server names.
		hookEntry := map[string]any{
			"matcher": "mcp__argus.*__kb_ingest",
			"hooks": []any{
				map[string]any{
					"type":    "command",
					"command": hookCmd,
				},
			},
		}

		hooks, _ := settings["hooks"].(map[string]any)
		if hooks == nil {
			hooks = make(map[string]any)
		}

		postToolUse, _ := hooks["PostToolUse"].([]any)

		for _, existing := range postToolUse {
			if entry, ok := existing.(map[string]any); ok {
				if entry["matcher"] == "mcp__argus.*__kb_ingest" {
					return false // already registered
				}
			}
		}

		postToolUse = append(postToolUse, hookEntry)
		hooks["PostToolUse"] = postToolUse
		settings["hooks"] = hooks
		return true
	})

	if changed {
		log.Success("Registered Argus KB change tracking hook (PostToolUse)")
	}
}

// registerStatusLine configures the Claude Code status line to show context
// window usage and compaction proximity via ~/.claude/settings.json.
func registerStatusLine() {
	changed := mutateSettings(func(settings map[string]any) bool {
		scriptPath := path.FromDots("agents/hooks/statusline.sh")
		statusLine := map[string]any{
			"type":    "command",
			"command": "bash \"" + scriptPath + "\"",
		}

		if existing, ok := settings["statusLine"].(map[string]any); ok {
			if existing["command"] == statusLine["command"] {
				return false // already registered
			}
		}

		settings["statusLine"] = statusLine
		return true
	})

	if changed {
		log.Success("Registered status line (context usage)")
	}
}

func ensureDir(dir string) bool {
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Error("Failed to create directory %s: %s", dir, err.Error())
		return false
	}
	return true
}
