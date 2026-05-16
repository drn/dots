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

	// Register session-end raw capture into memory/inbox/
	registerSessionEndCaptureHook()

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

// registerMatcherHook adds an entry to settings.hooks[eventName] that uses a
// `matcher` field for deduplication (PreToolUse / PostToolUse style).
func registerMatcherHook(eventName, matcher, scriptPath, successMsg string) {
	changed := mutateSettings(func(settings map[string]any) bool {
		hookCmd := "bash \"" + path.FromDots("%s", scriptPath) + "\""
		hookEntry := map[string]any{
			"matcher": matcher,
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

		entries, _ := hooks[eventName].([]any)
		for _, existing := range entries {
			if entry, ok := existing.(map[string]any); ok {
				if entry["matcher"] == matcher {
					return false // already registered
				}
			}
		}

		hooks[eventName] = append(entries, hookEntry)
		settings["hooks"] = hooks
		return true
	})

	if changed {
		log.Success("%s", successMsg)
	}
}

// registerSessionHook adds an entry to settings.hooks[eventName] for events
// without a `matcher` field (SessionStart / SessionEnd). Dedup is by inner
// command string.
func registerSessionHook(eventName, scriptPath, successMsg string) {
	changed := mutateSettings(func(settings map[string]any) bool {
		hookCmd := "bash \"" + path.FromDots("%s", scriptPath) + "\""
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

		entries, _ := hooks[eventName].([]any)
		for _, existing := range entries {
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

		hooks[eventName] = append(entries, hookEntry)
		settings["hooks"] = hooks
		return true
	})

	if changed {
		log.Success("%s", successMsg)
	}
}

func registerSkillTrackingHook() {
	registerMatcherHook(
		"PreToolUse",
		"Skill",
		"agents/hooks/track-skill-use.sh",
		"Registered skill usage tracking hook",
	)
}

func registerSessionStartMemoryHook() {
	registerSessionHook(
		"SessionStart",
		"agents/hooks/session-start-memory.sh",
		"Registered Argus KB memory injection hook (SessionStart)",
	)
}

func registerSessionEndCaptureHook() {
	registerSessionHook(
		"SessionEnd",
		"agents/hooks/session-end-capture.sh",
		"Registered session-end inbox capture hook (SessionEnd)",
	)
}

func registerKBChangeTrackingHook() {
	// Matcher covers both legacy and current Argus MCP server names.
	registerMatcherHook(
		"PostToolUse",
		"mcp__argus.*__kb_ingest",
		"agents/hooks/track-kb-change.sh",
		"Registered Argus KB change tracking hook (PostToolUse)",
	)
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
