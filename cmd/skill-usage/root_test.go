package main

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func writeTestLog(t *testing.T, lines string) string {
	t.Helper()
	dir := t.TempDir()
	p := filepath.Join(dir, "usage.jsonl")
	if err := os.WriteFile(p, []byte(lines), 0644); err != nil {
		t.Fatal(err)
	}
	return p
}

func TestLoadEntries_ParsesJSONL(t *testing.T) {
	log := `{"ts":"2026-03-20T10:00:00Z","skill":"pr","session_id":"s1","cwd":"/tmp"}
{"ts":"2026-03-21T10:00:00Z","skill":"test","session_id":"s2","cwd":"/tmp"}
{"ts":"2026-03-22T10:00:00Z","skill":"pr","session_id":"s3","cwd":"/tmp"}
`
	p := writeTestLog(t, log)
	entries := loadEntries(p, time.Time{})
	if len(entries) != 3 {
		t.Fatalf("got %d entries, want 3", len(entries))
	}
	if entries[0].Skill != "pr" {
		t.Errorf("entries[0].Skill = %q, want %q", entries[0].Skill, "pr")
	}
}

func TestLoadEntries_FiltersByCutoff(t *testing.T) {
	log := `{"ts":"2026-03-01T10:00:00Z","skill":"old","session_id":"s1","cwd":"/tmp"}
{"ts":"2026-03-22T10:00:00Z","skill":"new","session_id":"s2","cwd":"/tmp"}
`
	p := writeTestLog(t, log)
	cutoff := time.Date(2026, 3, 15, 0, 0, 0, 0, time.UTC)
	entries := loadEntries(p, cutoff)
	if len(entries) != 1 {
		t.Fatalf("got %d entries, want 1", len(entries))
	}
	if entries[0].Skill != "new" {
		t.Errorf("got skill %q, want %q", entries[0].Skill, "new")
	}
}

func TestLoadEntries_SkipsMalformedLines(t *testing.T) {
	log := `not json
{"ts":"2026-03-22T10:00:00Z","skill":"","session_id":"s1","cwd":"/tmp"}
{"ts":"2026-03-22T10:00:00Z","skill":"good","session_id":"s2","cwd":"/tmp"}
`
	p := writeTestLog(t, log)
	entries := loadEntries(p, time.Time{})
	if len(entries) != 1 {
		t.Fatalf("got %d entries, want 1", len(entries))
	}
}

func TestLoadEntries_MissingFile(t *testing.T) {
	entries := loadEntries("/nonexistent/file.jsonl", time.Time{})
	if entries != nil {
		t.Errorf("expected nil for missing file, got %d entries", len(entries))
	}
}

func TestCountBySkill(t *testing.T) {
	entries := []entry{
		{Skill: "pr"},
		{Skill: "test"},
		{Skill: "pr"},
		{Skill: "pr"},
		{Skill: "review"},
	}
	counts := countBySkill(entries)
	if counts["pr"] != 3 {
		t.Errorf("pr count = %d, want 3", counts["pr"])
	}
	if counts["test"] != 1 {
		t.Errorf("test count = %d, want 1", counts["test"])
	}
	if counts["review"] != 1 {
		t.Errorf("review count = %d, want 1", counts["review"])
	}
}

func TestSortedCounts_OrderAndTiebreak(t *testing.T) {
	counts := map[string]int{"beta": 5, "alpha": 5, "gamma": 1}
	sorted := sortedCounts(counts)
	if len(sorted) != 3 {
		t.Fatalf("got %d items, want 3", len(sorted))
	}
	// Same count: alphabetical
	if sorted[0].Name != "alpha" {
		t.Errorf("sorted[0] = %q, want %q", sorted[0].Name, "alpha")
	}
	if sorted[1].Name != "beta" {
		t.Errorf("sorted[1] = %q, want %q", sorted[1].Name, "beta")
	}
	// Lower count last
	if sorted[2].Name != "gamma" {
		t.Errorf("sorted[2] = %q, want %q", sorted[2].Name, "gamma")
	}
}

func TestDiscoverSkills(t *testing.T) {
	dir := t.TempDir()
	for _, name := range []string{"pr", "test", "review", "_shared", ".hidden"} {
		os.Mkdir(filepath.Join(dir, name), 0755)
	}
	// Create a file (should be ignored)
	os.WriteFile(filepath.Join(dir, "README.md"), []byte("hi"), 0644)

	skills := discoverSkills(dir)
	if len(skills) != 3 {
		t.Fatalf("got %d skills, want 3: %v", len(skills), skills)
	}
	expected := []string{"pr", "review", "test"}
	for i, name := range expected {
		if skills[i] != name {
			t.Errorf("skills[%d] = %q, want %q", i, skills[i], name)
		}
	}
}

func TestDiscoverSkills_MissingDir(t *testing.T) {
	skills := discoverSkills("/nonexistent/dir")
	if skills != nil {
		t.Errorf("expected nil for missing dir, got %v", skills)
	}
}

func TestBuildSuggestion(t *testing.T) {
	counts := map[string]int{"pr": 10, "test": 2, "review": 1}
	allSkills := []string{"debug", "pr", "review", "slack", "test"}

	s := buildSuggestion(counts, allSkills)

	if len(s.TopSkills) != 3 {
		t.Fatalf("top skills = %d, want 3", len(s.TopSkills))
	}
	if s.TopSkills[0].Name != "pr" {
		t.Errorf("top skill = %q, want %q", s.TopSkills[0].Name, "pr")
	}

	if len(s.NeverUsed) != 2 {
		t.Fatalf("never used = %d, want 2: %v", len(s.NeverUsed), s.NeverUsed)
	}

	if len(s.RarelyUsed) != 2 {
		t.Fatalf("rarely used = %d, want 2: %v", len(s.RarelyUsed), s.RarelyUsed)
	}
}
