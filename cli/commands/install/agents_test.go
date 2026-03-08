package install

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestMergeHooksIntoSettings_MergesAndPreservesExisting(t *testing.T) {
	tmpDir := t.TempDir()
	hooksPath := filepath.Join(tmpDir, "hooks.json")
	settingsPath := filepath.Join(tmpDir, "settings.json")

	os.WriteFile(hooksPath, []byte(`{"hooks":{"PreToolUse":[{"matcher":"Write","hooks":[{"type":"command","command":"$DOTS/test.sh"}]}]}}`), 0644)
	os.WriteFile(settingsPath, []byte(`{"env":{"FOO":"bar"},"mcpServers":{}}`), 0644)

	mergeHooksIntoSettings(hooksPath, settingsPath, "/resolved/dots")

	result, _ := os.ReadFile(settingsPath)
	var merged map[string]interface{}
	json.Unmarshal(result, &merged)

	// Verify existing settings preserved
	env, ok := merged["env"].(map[string]interface{})
	if !ok {
		t.Fatal("env key missing after merge")
	}
	if env["FOO"] != "bar" {
		t.Errorf("expected FOO=bar, got %v", env["FOO"])
	}

	// Verify hooks present
	hooks, ok := merged["hooks"].(map[string]interface{})
	if !ok {
		t.Fatal("hooks key missing after merge")
	}
	if _, ok := hooks["PreToolUse"]; !ok {
		t.Error("PreToolUse hook missing after merge")
	}
}

func TestMergeHooksIntoSettings_ResolvesDOTS(t *testing.T) {
	tmpDir := t.TempDir()
	hooksPath := filepath.Join(tmpDir, "hooks.json")
	settingsPath := filepath.Join(tmpDir, "settings.json")

	os.WriteFile(hooksPath, []byte(`{"hooks":{"PreToolUse":[{"hooks":[{"type":"command","command":"$DOTS/scripts/hook.sh"}]}]}}`), 0644)

	mergeHooksIntoSettings(hooksPath, settingsPath, "/home/user/.dots")

	result, _ := os.ReadFile(settingsPath)
	var merged map[string]interface{}
	json.Unmarshal(result, &merged)

	// Navigate to the command string and verify $DOTS was resolved
	hooks := merged["hooks"].(map[string]interface{})
	pre := hooks["PreToolUse"].([]interface{})
	entry := pre[0].(map[string]interface{})
	hookList := entry["hooks"].([]interface{})
	hook := hookList[0].(map[string]interface{})
	cmd := hook["command"].(string)

	if cmd != "/home/user/.dots/scripts/hook.sh" {
		t.Errorf("expected $DOTS resolved to absolute path, got %s", cmd)
	}
}

func TestMergeHooksIntoSettings_CreatesSettingsIfMissing(t *testing.T) {
	tmpDir := t.TempDir()
	hooksPath := filepath.Join(tmpDir, "hooks.json")
	settingsPath := filepath.Join(tmpDir, "settings.json")

	os.WriteFile(hooksPath, []byte(`{"hooks":{"Stop":[{"hooks":[{"type":"prompt","prompt":"check"}]}]}}`), 0644)

	mergeHooksIntoSettings(hooksPath, settingsPath, "/dots")

	result, _ := os.ReadFile(settingsPath)
	var merged map[string]interface{}
	json.Unmarshal(result, &merged)

	hooks, ok := merged["hooks"].(map[string]interface{})
	if !ok {
		t.Fatal("hooks key missing")
	}
	if _, ok := hooks["Stop"]; !ok {
		t.Error("Stop hook missing")
	}
}

func TestMergeHooksIntoSettings_MissingHooksFile(t *testing.T) {
	tmpDir := t.TempDir()

	// Should not panic or error when hooks file doesn't exist
	mergeHooksIntoSettings(
		filepath.Join(tmpDir, "nonexistent.json"),
		filepath.Join(tmpDir, "settings.json"),
		"/dots",
	)

	// settings.json should not be created
	if _, err := os.Stat(filepath.Join(tmpDir, "settings.json")); err == nil {
		t.Error("settings.json should not be created when hooks file is missing")
	}
}

func TestMergeHooksIntoSettings_MalformedSettingsJSON(t *testing.T) {
	tmpDir := t.TempDir()
	hooksPath := filepath.Join(tmpDir, "hooks.json")
	settingsPath := filepath.Join(tmpDir, "settings.json")

	os.WriteFile(hooksPath, []byte(`{"hooks":{"Stop":[]}}`), 0644)
	os.WriteFile(settingsPath, []byte(`{invalid json`), 0644)

	// Should not panic; should log error and return without modifying
	mergeHooksIntoSettings(hooksPath, settingsPath, "/dots")

	// Original malformed file should be unchanged
	result, _ := os.ReadFile(settingsPath)
	if string(result) != "{invalid json" {
		t.Error("malformed settings.json should be left unchanged")
	}
}

func TestMergeHooksIntoSettings_ReplacesExistingHooks(t *testing.T) {
	tmpDir := t.TempDir()
	hooksPath := filepath.Join(tmpDir, "hooks.json")
	settingsPath := filepath.Join(tmpDir, "settings.json")

	os.WriteFile(hooksPath, []byte(`{"hooks":{"Stop":[{"hooks":[{"type":"prompt","prompt":"new"}]}]}}`), 0644)
	os.WriteFile(settingsPath, []byte(`{"hooks":{"PreToolUse":[{"hooks":[{"type":"command","command":"old.sh"}]}]}}`), 0644)

	mergeHooksIntoSettings(hooksPath, settingsPath, "/dots")

	result, _ := os.ReadFile(settingsPath)
	var merged map[string]interface{}
	json.Unmarshal(result, &merged)

	hooks := merged["hooks"].(map[string]interface{})

	// New hooks should be present
	if _, ok := hooks["Stop"]; !ok {
		t.Error("Stop hook should be present after replacement")
	}

	// Old hooks should be gone (full replacement)
	if _, ok := hooks["PreToolUse"]; ok {
		t.Error("PreToolUse hook should be replaced (dots owns hooks key)")
	}
}
