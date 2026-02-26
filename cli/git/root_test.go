package git

import (
	"os"
	"os/exec"
	"testing"
)

func TestFilterBranches_Basic(t *testing.T) {
	input := []string{"origin/main", "origin/HEAD", "->", "origin/feature"}
	result := filterBranches(input)
	expected := []string{"origin/main", "origin/feature"}
	if len(result) != len(expected) {
		t.Fatalf("filterBranches length = %d, want %d", len(result), len(expected))
	}
	for i, v := range expected {
		if result[i] != v {
			t.Errorf("filterBranches[%d] = %q, want %q", i, result[i], v)
		}
	}
}

func TestFilterBranches_AllFiltered(t *testing.T) {
	input := []string{"->", "origin/HEAD", "upstream/HEAD"}
	result := filterBranches(input)
	if len(result) != 0 {
		t.Errorf("filterBranches = %v, want empty slice", result)
	}
}

func TestFilterBranches_Empty(t *testing.T) {
	result := filterBranches([]string{})
	if len(result) != 0 {
		t.Errorf("filterBranches(empty) = %v, want empty", result)
	}
}

func TestFilterBranches_NoneFiltered(t *testing.T) {
	input := []string{"origin/main", "origin/develop", "upstream/feature"}
	result := filterBranches(input)
	if len(result) != 3 {
		t.Errorf("filterBranches length = %d, want 3", len(result))
	}
}

func TestIsRepo_True(t *testing.T) {
	dir := t.TempDir()
	cmd := exec.Command("git", "init", dir)
	if err := cmd.Run(); err != nil {
		t.Skipf("git not available: %s", err)
	}
	orig, _ := os.Getwd()
	defer os.Chdir(orig)
	os.Chdir(dir)
	if !IsRepo() {
		t.Error("IsRepo() = false in a git repo, want true")
	}
}

func TestIsRepo_False(t *testing.T) {
	dir := t.TempDir()
	orig, _ := os.Getwd()
	defer os.Chdir(orig)
	os.Chdir(dir)
	if IsRepo() {
		t.Error("IsRepo() = true in a non-git dir, want false")
	}
}

func TestBranch_InRepo(t *testing.T) {
	dir := t.TempDir()
	cmd := exec.Command("git", "init", dir)
	if err := cmd.Run(); err != nil {
		t.Skipf("git not available: %s", err)
	}
	orig, _ := os.Getwd()
	defer os.Chdir(orig)
	os.Chdir(dir)

	// Create an initial commit so HEAD points to a branch
	exec.Command("git", "-C", dir, "config", "user.email", "test@test.com").Run()
	exec.Command("git", "-C", dir, "config", "user.name", "Test").Run()
	os.WriteFile(dir+"/file.txt", []byte("test"), 0644)
	exec.Command("git", "-C", dir, "add", ".").Run()
	exec.Command("git", "-C", dir, "commit", "-m", "init").Run()

	branch := Branch()
	if branch == "" {
		t.Error("Branch() returned empty string in a git repo with commits")
	}
}

func TestBranch_NotInRepo(t *testing.T) {
	dir := t.TempDir()
	orig, _ := os.Getwd()
	defer os.Chdir(orig)
	os.Chdir(dir)

	branch := Branch()
	if branch != "" {
		t.Errorf("Branch() = %q in non-git dir, want empty", branch)
	}
}
