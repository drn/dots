package install

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestSeedPiSettings_CreatesWhenMissing(t *testing.T) {
	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	if err := seedPiSettings(settingsPath); err != nil {
		t.Fatalf("seedPiSettings: %s", err)
	}

	got := readSettings(t, settingsPath)
	if got["defaultProvider"] != piDefaultProvider {
		t.Errorf("defaultProvider = %v, want %s", got["defaultProvider"], piDefaultProvider)
	}
	if got["defaultModel"] != piDefaultModel {
		t.Errorf("defaultModel = %v, want %s", got["defaultModel"], piDefaultModel)
	}
}

func TestSeedPiSettings_PreservesExistingFields(t *testing.T) {
	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")
	writeJSON(t, settingsPath, map[string]any{
		"lastChangelogVersion": "0.74.0",
		"steeringMode":         "auto",
	})

	if err := seedPiSettings(settingsPath); err != nil {
		t.Fatalf("seedPiSettings: %s", err)
	}

	got := readSettings(t, settingsPath)
	if got["lastChangelogVersion"] != "0.74.0" {
		t.Errorf("lastChangelogVersion = %v, want 0.74.0", got["lastChangelogVersion"])
	}
	if got["steeringMode"] != "auto" {
		t.Errorf("steeringMode = %v, want auto", got["steeringMode"])
	}
	if got["defaultProvider"] != piDefaultProvider {
		t.Errorf("defaultProvider = %v, want %s", got["defaultProvider"], piDefaultProvider)
	}
	if got["defaultModel"] != piDefaultModel {
		t.Errorf("defaultModel = %v, want %s", got["defaultModel"], piDefaultModel)
	}
}

func TestSeedPiSettings_IdempotentWhenAlreadySet(t *testing.T) {
	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")
	writeJSON(t, settingsPath, map[string]any{
		"defaultProvider": piDefaultProvider,
		"defaultModel":    piDefaultModel,
	})

	info, err := os.Stat(settingsPath)
	if err != nil {
		t.Fatalf("stat: %s", err)
	}
	mtime := info.ModTime()

	if err := seedPiSettings(settingsPath); err != nil {
		t.Fatalf("seedPiSettings: %s", err)
	}

	after, err := os.Stat(settingsPath)
	if err != nil {
		t.Fatalf("stat: %s", err)
	}
	if !after.ModTime().Equal(mtime) {
		t.Errorf("file rewritten when both defaults already match (mtime changed)")
	}
}

func TestSeedPiSettings_OverwritesExistingDefaults(t *testing.T) {
	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")
	writeJSON(t, settingsPath, map[string]any{
		"defaultProvider": "openai",
		"defaultModel":    "gpt-5",
	})

	if err := seedPiSettings(settingsPath); err != nil {
		t.Fatalf("seedPiSettings: %s", err)
	}

	got := readSettings(t, settingsPath)
	if got["defaultProvider"] != piDefaultProvider {
		t.Errorf("defaultProvider = %v, want %s", got["defaultProvider"], piDefaultProvider)
	}
	if got["defaultModel"] != piDefaultModel {
		t.Errorf("defaultModel = %v, want %s", got["defaultModel"], piDefaultModel)
	}
}

func TestSeedPiSettings_EmptyFile(t *testing.T) {
	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")
	if err := os.WriteFile(settingsPath, nil, 0644); err != nil {
		t.Fatalf("write empty file: %s", err)
	}

	if err := seedPiSettings(settingsPath); err != nil {
		t.Fatalf("seedPiSettings: %s", err)
	}

	got := readSettings(t, settingsPath)
	if got["defaultProvider"] != piDefaultProvider || got["defaultModel"] != piDefaultModel {
		t.Errorf("defaults not seeded into empty file: %v", got)
	}
}

func TestSeedPiSettings_MalformedJSON(t *testing.T) {
	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte("{not json"), 0644); err != nil {
		t.Fatalf("write malformed: %s", err)
	}

	if err := seedPiSettings(settingsPath); err == nil {
		t.Error("expected error for malformed JSON, got nil")
	}
}

func writeJSON(t *testing.T, path string, v any) {
	t.Helper()
	data, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("marshal: %s", err)
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		t.Fatalf("write %s: %s", path, err)
	}
}

func readSettings(t *testing.T, path string) map[string]any {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %s", path, err)
	}
	var out map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		t.Fatalf("unmarshal: %s", err)
	}
	return out
}
