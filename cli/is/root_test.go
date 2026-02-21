package is

import (
	"os"
	"path/filepath"
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
