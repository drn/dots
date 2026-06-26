package log //revive:disable-line:var-naming

import (
	"bytes"
	"testing"

	"github.com/fatih/color"
)

// captureAt runs fn at the given log level and returns what was written to the
// color output, restoring global state afterwards.
func captureAt(level Level, fn func()) string {
	prevLevel := currentLevel
	prevOutput := color.Output
	prevNoColor := color.NoColor
	defer func() {
		currentLevel = prevLevel
		color.Output = prevOutput
		color.NoColor = prevNoColor
	}()

	var buf bytes.Buffer
	color.NoColor = true
	color.Output = &buf
	SetLevel(level)
	fn()
	return buf.String()
}

func TestSetGetLevel_Roundtrip(t *testing.T) {
	defer SetLevel(LevelNormal)
	for _, level := range []Level{LevelQuiet, LevelNormal, LevelVerbose} {
		SetLevel(level)
		if GetLevel() != level {
			t.Errorf("GetLevel() = %d, want %d", GetLevel(), level)
		}
	}
}

func TestQuiet_SuppressesInformational(t *testing.T) {
	if out := captureAt(LevelQuiet, func() { Info("hidden") }); out != "" {
		t.Errorf("Info at quiet level emitted %q, want empty", out)
	}
	if out := captureAt(LevelQuiet, func() { Action("hidden") }); out != "" {
		t.Errorf("Action at quiet level emitted %q, want empty", out)
	}
	if out := captureAt(LevelQuiet, func() { Command("echo hi") }); out != "" {
		t.Errorf("Command at quiet level emitted %q, want empty", out)
	}
}

func TestQuiet_KeepsWarningsAndErrors(t *testing.T) {
	if out := captureAt(LevelQuiet, func() { Warning("warn") }); out == "" {
		t.Error("Warning at quiet level was suppressed, want emitted")
	}
	if out := captureAt(LevelQuiet, func() { Error("boom") }); out == "" {
		t.Error("Error at quiet level was suppressed, want emitted")
	}
}

func TestDebug_OnlyAtVerbose(t *testing.T) {
	if out := captureAt(LevelNormal, func() { Debug("detail") }); out != "" {
		t.Errorf("Debug at normal level emitted %q, want empty", out)
	}
	if out := captureAt(LevelVerbose, func() { Debug("detail") }); out == "" {
		t.Error("Debug at verbose level was suppressed, want emitted")
	}
}

func TestNormal_EmitsInformational(t *testing.T) {
	if out := captureAt(LevelNormal, func() { Info("shown") }); out == "" {
		t.Error("Info at normal level was suppressed, want emitted")
	}
}

func TestAction_NoPanic(_ *testing.T) {
	Action("test %s", "action")
}

func TestInfo_NoPanic(_ *testing.T) {
	Info("test %s", "info")
}

func TestSuccess_NoPanic(_ *testing.T) {
	Success("done")
}

func TestError_NoPanic(_ *testing.T) {
	Error("fail %d", 42)
}

func TestWarning_NoPanic(_ *testing.T) {
	Warning("warn")
}

func TestCommand_NoPanic(_ *testing.T) {
	Command("echo hello")
}

func TestRaw_NoPanic(_ *testing.T) {
	Raw("raw output")
}

func TestAction_FormatArgs(_ *testing.T) {
	Action("installing %s version %d", "ruby", 3)
}

func TestCommand_PathPretty(_ *testing.T) {
	// Command() calls path.Pretty() internally - verify it handles various paths
	Command("/usr/local/bin/test")
	Command("~/some/path")
}
