package log //revive:disable-line:var-naming

import (
	"testing"
)

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
