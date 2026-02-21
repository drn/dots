package path //revive:disable-line:var-naming

import (
	"os"
	"os/user"
	"strings"
	"testing"
)

func TestHome(t *testing.T) {
	home := Home()
	if home == "" {
		t.Error("Home() returned empty string")
	}
	u, _ := user.Current()
	if home != u.HomeDir {
		t.Errorf("Home() = %s, want %s", home, u.HomeDir)
	}
}

func TestDots(t *testing.T) {
	// Test with DOTS env set
	original := os.Getenv("DOTS")
	os.Setenv("DOTS", "/custom/dots")
	defer os.Setenv("DOTS", original)

	if got := Dots(); got != "/custom/dots" {
		t.Errorf("Dots() = %s, want /custom/dots", got)
	}

	// Test fallback when DOTS is empty
	os.Unsetenv("DOTS")
	expected := Home() + "/.dots"
	if got := Dots(); got != expected {
		t.Errorf("Dots() = %s, want %s", got, expected)
	}
}

func TestFromDots(t *testing.T) {
	original := os.Getenv("DOTS")
	os.Setenv("DOTS", "/test/dots")
	defer os.Setenv("DOTS", original)

	if got := FromDots("vim"); got != "/test/dots/vim" {
		t.Errorf("FromDots('vim') = %s, want /test/dots/vim", got)
	}

	if got := FromDots("vim/%s", "colors"); got != "/test/dots/vim/colors" {
		t.Errorf("FromDots('vim/%%s', 'colors') = %s, want /test/dots/vim/colors", got)
	}
}

func TestFromHome(t *testing.T) {
	home := Home()
	if got := FromHome(".vimrc"); got != home+"/.vimrc" {
		t.Errorf("FromHome('.vimrc') = %s, want %s/.vimrc", got, home)
	}
}

func TestPretty(t *testing.T) {
	original := os.Getenv("DOTS")
	os.Setenv("DOTS", "/users/test/.dots")
	defer os.Setenv("DOTS", original)

	if got := Pretty("/users/test/.dots/vim"); got != "$DOTS/vim" {
		t.Errorf("Pretty() = %s, want $DOTS/vim", got)
	}

	home := Home()
	if got := Pretty(home + "/.config"); !strings.HasPrefix(got, "~") {
		t.Errorf("Pretty(%s/.config) = %s, expected to start with ~", home, got)
	}
}

func TestCache(t *testing.T) {
	home := Home()
	expected := home + "/.dots/sys/cache"
	if got := Cache(); got != expected {
		t.Errorf("Cache() = %s, want %s", got, expected)
	}
}

func TestFromCache(t *testing.T) {
	home := Home()
	expected := home + "/.dots/sys/cache/test-key"
	if got := FromCache("test-key"); got != expected {
		t.Errorf("FromCache('test-key') = %s, want %s", got, expected)
	}
}
