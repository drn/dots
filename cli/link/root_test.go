package link

import (
	"os"
	"path/filepath"
	"testing"
)

func TestSoft(t *testing.T) {
	dir := t.TempDir()
	source := filepath.Join(dir, "source")
	os.WriteFile(source, []byte("content"), 0644)
	target := filepath.Join(dir, "target")

	Soft(source, target)

	info, err := os.Lstat(target)
	if err != nil {
		t.Fatalf("expected symlink to exist: %s", err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Error("expected target to be a symlink")
	}
	resolved, err := os.Readlink(target)
	if err != nil {
		t.Fatalf("failed to read symlink: %s", err)
	}
	if resolved != source {
		t.Errorf("symlink points to %s, want %s", resolved, source)
	}
}

func TestSoftOverwrite(t *testing.T) {
	dir := t.TempDir()
	source1 := filepath.Join(dir, "source1")
	source2 := filepath.Join(dir, "source2")
	os.WriteFile(source1, []byte("first"), 0644)
	os.WriteFile(source2, []byte("second"), 0644)
	target := filepath.Join(dir, "target")

	Soft(source1, target)
	Soft(source2, target)

	resolved, err := os.Readlink(target)
	if err != nil {
		t.Fatalf("failed to read symlink: %s", err)
	}
	if resolved != source2 {
		t.Errorf("symlink points to %s, want %s", resolved, source2)
	}
}

func TestHard(t *testing.T) {
	dir := t.TempDir()
	source := filepath.Join(dir, "source")
	os.WriteFile(source, []byte("content"), 0644)
	target := filepath.Join(dir, "target")

	Hard(source, target)

	data, err := os.ReadFile(target)
	if err != nil {
		t.Fatalf("expected hard link to exist: %s", err)
	}
	if string(data) != "content" {
		t.Errorf("hard link content = %s, want 'content'", string(data))
	}

	// Verify it's a hard link (same inode)
	sourceStat, _ := os.Stat(source)
	targetStat, _ := os.Stat(target)
	if !os.SameFile(sourceStat, targetStat) {
		t.Error("expected source and target to be the same file (hard link)")
	}
}

func TestHardOverwrite(t *testing.T) {
	dir := t.TempDir()
	source1 := filepath.Join(dir, "source1")
	source2 := filepath.Join(dir, "source2")
	os.WriteFile(source1, []byte("first"), 0644)
	os.WriteFile(source2, []byte("second"), 0644)
	target := filepath.Join(dir, "target")

	Hard(source1, target)
	Hard(source2, target)

	data, err := os.ReadFile(target)
	if err != nil {
		t.Fatalf("failed to read hard link: %s", err)
	}
	if string(data) != "second" {
		t.Errorf("hard link content = %s, want 'second'", string(data))
	}
}

func TestSoft_NonexistentSource(t *testing.T) {
	dir := t.TempDir()
	source := filepath.Join(dir, "nonexistent")
	target := filepath.Join(dir, "target")

	// Should create a dangling symlink without panicking
	Soft(source, target)

	_, err := os.Lstat(target)
	if err != nil {
		t.Fatalf("expected symlink to exist (even dangling): %s", err)
	}
	resolved, _ := os.Readlink(target)
	if resolved != source {
		t.Errorf("symlink points to %s, want %s", resolved, source)
	}
}

func TestHard_NonexistentSource(t *testing.T) {
	dir := t.TempDir()
	source := filepath.Join(dir, "nonexistent")
	target := filepath.Join(dir, "target")

	// Hard link to nonexistent source should fail gracefully
	Hard(source, target)

	if _, err := os.Stat(target); err == nil {
		t.Error("expected target not to exist for hard link to nonexistent source")
	}
}

func TestRemoveExisting_NoFile(t *testing.T) {
	dir := t.TempDir()
	target := filepath.Join(dir, "nonexistent")
	// Should not panic when target doesn't exist
	removeExisting(target)
}

func TestRemoveExisting_RegularFile(t *testing.T) {
	dir := t.TempDir()
	target := filepath.Join(dir, "file")
	os.WriteFile(target, []byte("content"), 0644)

	removeExisting(target)

	if _, err := os.Stat(target); !os.IsNotExist(err) {
		t.Error("expected file to be removed")
	}
}

func TestSoft_TargetIsDirectory(t *testing.T) {
	dir := t.TempDir()
	source := filepath.Join(dir, "source")
	os.WriteFile(source, []byte("content"), 0644)
	target := filepath.Join(dir, "targetdir")
	os.Mkdir(target, 0755)

	Soft(source, target)

	info, err := os.Lstat(target)
	if err != nil {
		t.Fatalf("expected symlink: %s", err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Error("expected target to be a symlink")
	}
}
