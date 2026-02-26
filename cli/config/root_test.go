package config

import (
	"os"
	"testing"
)

func TestParsePath_TwoSegments(t *testing.T) {
	section, key := parsePath("spotify.token")
	if section == nil || *section != "spotify" {
		t.Errorf("parsePath section = %v, want 'spotify'", section)
	}
	if key == nil || *key != "token" {
		t.Errorf("parsePath key = %v, want 'token'", key)
	}
}

func TestParsePath_OneSegment(t *testing.T) {
	section, key := parsePath("spotify")
	if section == nil || *section != "spotify" {
		t.Errorf("parsePath section = %v, want 'spotify'", section)
	}
	if key != nil {
		t.Errorf("parsePath key = %v, want nil", key)
	}
}

func TestParsePath_Empty(t *testing.T) {
	section, key := parsePath("")
	if section == nil {
		t.Error("parsePath('') section is nil, want non-nil")
	}
	if key != nil {
		t.Errorf("parsePath('') key = %v, want nil", key)
	}
}

func TestValidateInput_Blank(t *testing.T) {
	if err := validateInput(""); err == nil {
		t.Error("validateInput('') returned nil, want error")
	}
	if err := validateInput("   "); err == nil {
		t.Error("validateInput('   ') returned nil, want error")
	}
}

func TestValidateInput_Valid(t *testing.T) {
	if err := validateInput("hello"); err != nil {
		t.Errorf("validateInput('hello') returned error: %s", err)
	}
}

func TestReadWriteDelete(t *testing.T) {
	tmpDir := t.TempDir()
	t.Setenv("HOME", tmpDir)

	// Create the config directory
	os.MkdirAll(tmpDir+"/.dots/sys", 0755)

	// Write
	ok := Write("test.key", "myvalue")
	if !ok {
		t.Fatal("Write('test.key', 'myvalue') returned false")
	}

	// Read
	value := Read("test.key")
	if value != "myvalue" {
		t.Errorf("Read('test.key') = %q, want %q", value, "myvalue")
	}

	// Delete
	Delete("test.key")
	value = Read("test.key")
	if value != "" {
		t.Errorf("Read after Delete = %q, want empty", value)
	}
}

func TestAll(t *testing.T) {
	tmpDir := t.TempDir()
	t.Setenv("HOME", tmpDir)
	os.MkdirAll(tmpDir+"/.dots/sys", 0755)

	Write("section1.key1", "val1")
	Write("section1.key2", "val2")
	Write("section2.key3", "val3")

	all := All()
	if len(all) < 2 {
		t.Errorf("All() returned %d sections, want at least 2", len(all))
	}
	if all["section1"]["key1"] != "val1" {
		t.Errorf("All()['section1']['key1'] = %q, want 'val1'", all["section1"]["key1"])
	}
}

func TestRead_MissingKey(t *testing.T) {
	tmpDir := t.TempDir()
	t.Setenv("HOME", tmpDir)
	os.MkdirAll(tmpDir+"/.dots/sys", 0755)

	value := Read("nonexistent.key")
	if value != "" {
		t.Errorf("Read('nonexistent.key') = %q, want empty", value)
	}
}
