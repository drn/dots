package is

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

func TestFileExists(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "testfile")
	os.WriteFile(path, []byte("test"), 0644)

	if !File(path) {
		t.Errorf("File(%s) = false, want true", path)
	}
}

func TestFileNotExists(t *testing.T) {
	if File("/nonexistent/path/to/file") {
		t.Error("File('/nonexistent/path/to/file') = true, want false")
	}
}

func TestCommandExists(t *testing.T) {
	// "ls" should exist on all systems
	if !Command("ls") {
		t.Error("Command('ls') = false, want true")
	}
}

func TestCommandNotExists(t *testing.T) {
	if Command("definitely-not-a-real-command-12345") {
		t.Error("Command('definitely-not-a-real-command-12345') = true, want false")
	}
}

func TestTmux_NotInTmux(t *testing.T) {
	t.Setenv("TMUX", "")
	t.Setenv("TERM", "xterm-256color")
	if Tmux() {
		t.Error("Tmux() = true outside tmux, want false")
	}
}

func TestTmux_ScreenTermNoTmuxEnv(t *testing.T) {
	t.Setenv("TERM", "screen-256color")
	t.Setenv("TMUX", "")
	if Tmux() {
		t.Error("Tmux() = true with screen TERM but empty TMUX, want false")
	}
}

func TestTmux_NonScreenTermWithTmuxEnv(t *testing.T) {
	t.Setenv("TERM", "xterm-256color")
	t.Setenv("TMUX", "/tmp/tmux-501/default,12345,0")
	if Tmux() {
		t.Error("Tmux() = true with non-screen TERM, want false")
	}
}

func TestOsx(t *testing.T) {
	expected := runtime.GOOS == "darwin"
	if Osx() != expected {
		t.Errorf("Osx() = %v, want %v (GOOS=%s)", Osx(), expected, runtime.GOOS)
	}
}
