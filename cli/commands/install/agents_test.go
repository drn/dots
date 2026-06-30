package install

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/drn/dots/pkg/path"
)

// path.SetHome is package-global state. Tests in this file MUST NOT call
// t.Parallel() — see the note in root_test.go.

// setupClaudeHome points DOTS and HOME at temp dirs and creates ~/.claude so
// settings mutation has somewhere to write. Returns the settings.json path.
func setupClaudeHome(t *testing.T) string {
	t.Helper()
	dots := t.TempDir()
	home := t.TempDir()
	t.Setenv("DOTS", dots)
	path.SetHome(home)
	t.Cleanup(func() { path.SetHome("") })

	if err := os.MkdirAll(filepath.Join(home, ".claude"), 0755); err != nil {
		t.Fatalf("mkdir .claude: %s", err)
	}
	return filepath.Join(home, ".claude", "settings.json")
}

// sessionStartCommands returns every inner command string registered under the
// SessionStart hook event in the given settings file.
func sessionStartCommands(t *testing.T, settingsPath string) []string {
	t.Helper()
	settings := readSettings(t, settingsPath)

	hooks, _ := settings["hooks"].(map[string]any)
	entries, _ := hooks["SessionStart"].([]any)

	var cmds []string
	for _, e := range entries {
		entry, _ := e.(map[string]any)
		inner, _ := entry["hooks"].([]any)
		for _, h := range inner {
			cmd, _ := h.(map[string]any)
			if s, ok := cmd["command"].(string); ok {
				cmds = append(cmds, s)
			}
		}
	}
	return cmds
}

// countContaining counts command strings that mention needle.
func countContaining(cmds []string, needle string) int {
	n := 0
	for _, c := range cmds {
		if strings.Contains(c, needle) {
			n++
		}
	}
	return n
}

func TestRegisterSessionStartPathHook_AddsHook(t *testing.T) {
	settingsPath := setupClaudeHome(t)

	registerSessionStartPathHook()

	cmds := sessionStartCommands(t, settingsPath)
	if got := countContaining(cmds, "agents/hooks/session-start-path.sh"); got != 1 {
		t.Fatalf("session-start-path.sh registered %d times, want 1 (cmds=%v)", got, cmds)
	}
}

func TestRegisterSessionStartPathHook_Idempotent(t *testing.T) {
	settingsPath := setupClaudeHome(t)

	registerSessionStartPathHook()
	registerSessionStartPathHook()

	cmds := sessionStartCommands(t, settingsPath)
	if got := countContaining(cmds, "agents/hooks/session-start-path.sh"); got != 1 {
		t.Fatalf("session-start-path.sh registered %d times after re-run, want 1 (cmds=%v)", got, cmds)
	}
}

func TestRegisterSessionStartPathHook_CoexistsWithMemoryHook(t *testing.T) {
	settingsPath := setupClaudeHome(t)

	// Both hooks live under SessionStart and must not collide: dedup is by
	// inner command string, and the two scripts differ.
	registerSessionStartMemoryHook()
	registerSessionStartPathHook()

	cmds := sessionStartCommands(t, settingsPath)
	if got := countContaining(cmds, "agents/hooks/session-start-memory.sh"); got != 1 {
		t.Errorf("memory hook present %d times, want 1 (cmds=%v)", got, cmds)
	}
	if got := countContaining(cmds, "agents/hooks/session-start-path.sh"); got != 1 {
		t.Errorf("path hook present %d times, want 1 (cmds=%v)", got, cmds)
	}
}

func TestRegisterSessionStartPathHook_CommandShape(t *testing.T) {
	settingsPath := setupClaudeHome(t)

	registerSessionStartPathHook()

	want := "bash \"" + path.FromDots("agents/hooks/session-start-path.sh") + "\""
	cmds := sessionStartCommands(t, settingsPath)
	found := false
	for _, c := range cmds {
		if c == want {
			found = true
		}
	}
	if !found {
		t.Errorf("no SessionStart command equal to %q (cmds=%v)", want, cmds)
	}
}
