package install

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/drn/dots/pkg/path"
)

func TestEnsureCodexStatusLine_CreatesStatusLine(t *testing.T) {
	got, changed, err := ensureCodexStatusLine("")
	if err != nil {
		t.Fatal(err)
	}
	if !changed {
		t.Fatal("expected new status line to be added")
	}
	want := `["model-with-reasoning", "context-remaining", "five-hour-limit", "weekly-limit"]`
	if !strings.Contains(got, want) {
		t.Fatalf("status line array = %q, want it to contain %q", got, want)
	}
	for _, item := range codexStatusLineItems {
		if !strings.Contains(got, `"`+item+`"`) {
			t.Errorf("status line does not include %q: %s", item, got)
		}
	}
}

func TestEnsureCodexStatusLine_PreservesExistingSettingsAndItems(t *testing.T) {
	config := "model = \"gpt-5\"\n\n[tui]\nshow_tooltips = false\nstatus_line = [\"git-branch\", \"weekly-limit\"]\n\n[projects.\"/repo\"]\ntrust_level = \"trusted\"\n"
	got, changed, err := ensureCodexStatusLine(config)
	if err != nil {
		t.Fatal(err)
	}
	if !changed {
		t.Fatal("expected status line to be extended")
	}
	for _, want := range []string{
		`model = "gpt-5"`,
		`show_tooltips = false`,
		`"git-branch"`,
		`"weekly-limit"`,
		`[projects."/repo"]`,
		`trust_level = "trusted"`,
	} {
		if !strings.Contains(got, want) {
			t.Errorf("updated config lost %q:\n%s", want, got)
		}
	}
	if strings.Count(got, `"weekly-limit"`) != 1 {
		t.Errorf("weekly-limit duplicated in status line:\n%s", got)
	}
	wantArray := `status_line = ["git-branch", "weekly-limit", "model-with-reasoning", "context-remaining", "five-hour-limit"]`
	if !strings.Contains(got, wantArray) {
		t.Errorf("serialized status line = %q, want %q", got, wantArray)
	}
}

func TestEnsureCodexStatusLine_HandlesMultilineAndDottedKey(t *testing.T) {
	config := "tui.status_line = [\n  \"git-branch\", # keep this item\n]\n"
	got, changed, err := ensureCodexStatusLine(config)
	if err != nil {
		t.Fatal(err)
	}
	if !changed {
		t.Fatal("expected status line to be extended")
	}
	if !strings.Contains(got, `"git-branch"`) || !strings.Contains(got, `"five-hour-limit"`) {
		t.Errorf("updated dotted status line is missing expected items:\n%s", got)
	}
	if !strings.Contains(got, "# keep this item") {
		t.Errorf("updated status line dropped an existing comment:\n%s", got)
	}
}

func TestEnsureCodexStatusLine_HandlesTableHeaderComment(t *testing.T) {
	config := "[tui] # existing Codex settings\nshow_tooltips = false\n"
	got, changed, err := ensureCodexStatusLine(config)
	if err != nil {
		t.Fatal(err)
	}
	if !changed {
		t.Fatal("expected status line to be added")
	}
	if strings.Count(got, "[tui]") != 1 || !strings.Contains(got, "# existing Codex settings") {
		t.Fatalf("table header comment or table was not preserved:\n%s", got)
	}
	if !strings.Contains(got, `"weekly-limit"`) {
		t.Fatalf("status line limits missing:\n%s", got)
	}
}

func TestEnsureCodexStatusLine_ReplacesNullStatusLine(t *testing.T) {
	config := "[tui]\nstatus_line = null # Codex default\n"
	got, changed, err := ensureCodexStatusLine(config)
	if err != nil {
		t.Fatal(err)
	}
	if !changed {
		t.Fatal("expected null status line to be configured")
	}
	if !strings.Contains(got, `status_line = ["model-with-reasoning", "context-remaining", "five-hour-limit", "weekly-limit"] # Codex default`) {
		t.Fatalf("null status line was not replaced while preserving its comment:\n%s", got)
	}
}

func TestEnsureCodexStatusLine_Idempotent(t *testing.T) {
	first, changed, err := ensureCodexStatusLine("[tui]\nstatus_line = [\"git-branch\"]\n")
	if err != nil {
		t.Fatal(err)
	}
	if !changed {
		t.Fatal("expected first call to add status line items")
	}
	second, changed, err := ensureCodexStatusLine(first)
	if err != nil {
		t.Fatal(err)
	}
	if changed {
		t.Fatal("expected second call to be a no-op")
	}
	if second != first {
		t.Fatal("second call changed the Codex config")
	}
}

func TestEnsureCodexStatusLine_RejectsUnexpectedValue(t *testing.T) {
	config := "[tui]\nstatus_line = false\n"
	got, changed, err := ensureCodexStatusLine(config)
	if err == nil {
		t.Fatal("expected invalid status_line value to fail")
	}
	if changed || got != config {
		t.Fatal("invalid config should remain unchanged")
	}
}

func TestEnsureCodexStatusLine_RejectsMissingArrayComma(t *testing.T) {
	config := "[tui]\nstatus_line = [\"git-branch\" \"weekly-limit\"]\n"
	got, changed, err := ensureCodexStatusLine(config)
	if err == nil {
		t.Fatal("expected invalid array syntax to fail")
	}
	if changed || got != config {
		t.Fatal("invalid array syntax should remain unchanged")
	}
}

func TestRegisterCodexStatusLine_UsesCodexHome(t *testing.T) {
	home := t.TempDir()
	configPath := filepath.Join(home, "config.toml")
	if err := os.WriteFile(configPath, []byte("model = \"gpt-5\"\n"), 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("CODEX_HOME", home)
	path.SetHome(t.TempDir())
	t.Cleanup(func() { path.SetHome("") })

	registerCodexStatusLine()

	data, err := os.ReadFile(configPath)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), `"five-hour-limit"`) {
		t.Errorf("Codex config did not receive status-line items:\n%s", data)
	}
}
