package main

import "testing"

func TestNextVersion_PatchFromExisting(t *testing.T) {
	tests := []struct {
		latest string
		bump   string
		want   string
	}{
		{"v1.2.3", "patch", "v1.2.4"},
		{"v1.2.3", "minor", "v1.3.0"},
		{"v1.2.3", "major", "v2.0.0"},
		{"v0.0.0", "patch", "v0.0.1"},
		{"v0.0.0", "minor", "v0.1.0"},
		{"v0.0.0", "major", "v1.0.0"},
		{"v10.20.30", "patch", "v10.20.31"},
		{"v10.20.30", "minor", "v10.21.0"},
		{"v10.20.30", "major", "v11.0.0"},
	}

	for _, tt := range tests {
		got := nextVersion(tt.latest, tt.bump)
		if got != tt.want {
			t.Errorf("nextVersion(%q, %q) = %q, want %q", tt.latest, tt.bump, got, tt.want)
		}
	}
}

func TestNextVersion_FromEmpty(t *testing.T) {
	tests := []struct {
		bump string
		want string
	}{
		{"patch", "v0.0.1"},
		{"minor", "v0.1.0"},
		{"major", "v1.0.0"},
	}

	for _, tt := range tests {
		got := nextVersion("", tt.bump)
		if got != tt.want {
			t.Errorf("nextVersion(%q, %q) = %q, want %q", "", tt.bump, got, tt.want)
		}
	}
}

func TestNextVersion_ResetsLowerComponents(t *testing.T) {
	got := nextVersion("v1.5.9", "minor")
	if got != "v1.6.0" {
		t.Errorf("minor bump should reset patch: got %q, want %q", got, "v1.6.0")
	}

	got = nextVersion("v1.5.9", "major")
	if got != "v2.0.0" {
		t.Errorf("major bump should reset minor and patch: got %q, want %q", got, "v2.0.0")
	}
}
