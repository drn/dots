package install

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/drn/dots/pkg/path"
)

func TestCall_UnknownCommand(_ *testing.T) {
	// Should be a no-op, not panic
	Call("definitely-not-a-command")
}

func TestCall_EmptyCommand(_ *testing.T) {
	// Should be a no-op, not panic
	Call("")
}

func TestLinkDirEntries(t *testing.T) {
	dots := t.TempDir()
	home := t.TempDir()
	t.Setenv("DOTS", dots)
	path.SetHome(home)
	t.Cleanup(func() { path.SetHome("") })

	if err := os.MkdirAll(filepath.Join(dots, "src"), 0755); err != nil {
		t.Fatalf("mkdir src: %s", err)
	}
	for _, name := range []string{"alpha", "bravo"} {
		if err := os.WriteFile(filepath.Join(dots, "src", name), []byte("x"), 0644); err != nil {
			t.Fatalf("write %s: %s", name, err)
		}
	}

	var calls [][2]string
	capture := func(from, to string) { calls = append(calls, [2]string{from, to}) }

	linkDirEntries("src", ".%s", capture)

	want := [][2]string{
		{filepath.Join(dots, "src", "alpha"), filepath.Join(home, ".alpha")},
		{filepath.Join(dots, "src", "bravo"), filepath.Join(home, ".bravo")},
	}
	if len(calls) != len(want) {
		t.Fatalf("linkFn called %d times, want %d (calls=%v)", len(calls), len(want), calls)
	}
	for i, w := range want {
		if calls[i] != w {
			t.Errorf("call %d = %v, want %v", i, calls[i], w)
		}
	}
}

func TestLinkDirEntries_EmptyDir(t *testing.T) {
	dots := t.TempDir()
	t.Setenv("DOTS", dots)
	path.SetHome(t.TempDir())
	t.Cleanup(func() { path.SetHome("") })

	if err := os.MkdirAll(filepath.Join(dots, "empty"), 0755); err != nil {
		t.Fatalf("mkdir empty: %s", err)
	}

	called := false
	linkDirEntries("empty", ".%s", func(_, _ string) { called = true })

	if called {
		t.Error("linkFn should not be called for an empty source directory")
	}
}

func TestLinkDirEntries_MissingDir(t *testing.T) {
	t.Setenv("DOTS", t.TempDir())
	path.SetHome(t.TempDir())
	t.Cleanup(func() { path.SetHome("") })

	called := false
	// Source dir does not exist — must warn and return without panicking
	// or calling linkFn.
	linkDirEntries("nope", ".%s", func(_, _ string) { called = true })

	if called {
		t.Error("linkFn should not be called when source dir is missing")
	}
}
