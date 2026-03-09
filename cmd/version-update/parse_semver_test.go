package main

import "testing"

func TestParseSemver_Valid(t *testing.T) {
	tests := []struct {
		input               string
		major, minor, patch int
	}{
		{"v1.2.3", 1, 2, 3},
		{"v0.0.0", 0, 0, 0},
		{"v10.20.30", 10, 20, 30},
		{"1.2.3", 1, 2, 3},
	}

	for _, tt := range tests {
		v, ok := parseSemver(tt.input)
		if !ok {
			t.Errorf("parseSemver(%q) returned ok=false, want true", tt.input)
			continue
		}
		if v.major != tt.major || v.minor != tt.minor || v.patch != tt.patch {
			t.Errorf("parseSemver(%q) = %d.%d.%d, want %d.%d.%d",
				tt.input, v.major, v.minor, v.patch, tt.major, tt.minor, tt.patch)
		}
		if v.tag != tt.input {
			t.Errorf("parseSemver(%q).tag = %q", tt.input, v.tag)
		}
	}
}

func TestParseSemver_Invalid(t *testing.T) {
	tests := []string{
		"",
		"v1.2",
		"v1",
		"abc",
		"v1.2.abc",
		"v1.abc.3",
		"vabc.2.3",
	}

	for _, input := range tests {
		_, ok := parseSemver(input)
		if ok {
			t.Errorf("parseSemver(%q) returned ok=true, want false", input)
		}
	}
}
