package tmux

import (
	"testing"
)

func TestWindow_NotInTmux(t *testing.T) {
	t.Setenv("TMUX", "")
	t.Setenv("TERM", "xterm-256color")
	name, number := Window()
	if name != "" || number != 0 {
		t.Errorf("Window() = (%q, %d), want (\"\", 0)", name, number)
	}
}

func TestSetWindow_NotInTmux(t *testing.T) {
	t.Setenv("TMUX", "")
	t.Setenv("TERM", "xterm-256color")
	// Should be a no-op, verify no panic
	SetWindow("test", 1)
}

func TestSetWindow_EmptyName(t *testing.T) {
	// Even if TMUX is set, empty name should no-op
	t.Setenv("TMUX", "/tmp/tmux-501/default,12345,0")
	t.Setenv("TERM", "screen-256color")
	SetWindow("", 1)
}

func TestWindow_NoTmuxEnv(t *testing.T) {
	t.Setenv("TMUX", "")
	t.Setenv("TERM", "screen-256color")
	name, number := Window()
	if name != "" || number != 0 {
		t.Errorf("Window() without TMUX env = (%q, %d), want (\"\", 0)", name, number)
	}
}
