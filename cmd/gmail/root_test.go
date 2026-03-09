package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestDecodeBase64URL(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"simple", "aGVsbG8", "hello"},
		{"with padding chars", "aGVsbG8gd29ybGQ", "hello world"},
		{"empty", "", ""},
		{"invalid", "!!!invalid!!!", ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := decodeBase64URL(tt.input)
			if got != tt.expected {
				t.Errorf("decodeBase64URL(%q) = %q, want %q", tt.input, got, tt.expected)
			}
		})
	}
}

func TestGetHeader(t *testing.T) {
	payload := map[string]interface{}{
		"headers": []interface{}{
			map[string]interface{}{"name": "From", "value": "alice@example.com"},
			map[string]interface{}{"name": "Subject", "value": "Hello"},
			map[string]interface{}{"name": "Date", "value": "Mon, 1 Jan 2024"},
		},
	}

	tests := []struct {
		name     string
		header   string
		expected string
	}{
		{"exact match", "From", "alice@example.com"},
		{"case insensitive", "from", "alice@example.com"},
		{"subject", "Subject", "Hello"},
		{"missing header", "CC", ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := getHeader(payload, tt.header)
			if got != tt.expected {
				t.Errorf("getHeader(payload, %q) = %q, want %q", tt.header, got, tt.expected)
			}
		})
	}

	// nil headers
	if got := getHeader(map[string]interface{}{}, "From"); got != "" {
		t.Errorf("getHeader with no headers = %q, want empty", got)
	}
}

func TestExtractBody(t *testing.T) {
	t.Run("plain text body", func(t *testing.T) {
		payload := map[string]interface{}{
			"mimeType": "text/plain",
			"body": map[string]interface{}{
				"data": "aGVsbG8", // "hello"
			},
		}
		text, html := extractBody(payload)
		if text != "hello" {
			t.Errorf("text = %q, want %q", text, "hello")
		}
		if html != "" {
			t.Errorf("html = %q, want empty", html)
		}
	})

	t.Run("html body", func(t *testing.T) {
		payload := map[string]interface{}{
			"mimeType": "text/html",
			"body": map[string]interface{}{
				"data": "PGI-aGk8L2I-", // "<b>hi</b>"
			},
		}
		text, html := extractBody(payload)
		if text != "" {
			t.Errorf("text = %q, want empty", text)
		}
		if html != "<b>hi</b>" {
			t.Errorf("html = %q, want %q", html, "<b>hi</b>")
		}
	})

	t.Run("multipart with parts", func(t *testing.T) {
		payload := map[string]interface{}{
			"mimeType": "multipart/alternative",
			"parts": []interface{}{
				map[string]interface{}{
					"mimeType": "text/plain",
					"body":     map[string]interface{}{"data": "aGVsbG8"}, // "hello"
				},
				map[string]interface{}{
					"mimeType": "text/html",
					"body":     map[string]interface{}{"data": "PGI-aGk8L2I-"}, // "<b>hi</b>"
				},
			},
		}
		text, html := extractBody(payload)
		if text != "hello" {
			t.Errorf("text = %q, want %q", text, "hello")
		}
		if html != "<b>hi</b>" {
			t.Errorf("html = %q, want %q", html, "<b>hi</b>")
		}
	})

	t.Run("empty payload", func(t *testing.T) {
		text, html := extractBody(map[string]interface{}{})
		if text != "" || html != "" {
			t.Errorf("expected empty, got text=%q html=%q", text, html)
		}
	})
}

func TestResolveAccount(t *testing.T) {
	origDir := configDir
	defer func() { configDir = origDir }()

	t.Run("explicit account returned as-is", func(t *testing.T) {
		got := resolveAccount("work")
		if got != "work" {
			t.Errorf("resolveAccount('work') = %q, want 'work'", got)
		}
	})

	t.Run("default from accounts.json", func(t *testing.T) {
		dir := t.TempDir()
		configDir = dir
		os.MkdirAll(filepath.Join(dir, "tokens"), 0755)
		os.WriteFile(
			filepath.Join(dir, "accounts.json"),
			[]byte(`{"default":"personal"}`),
			0644,
		)
		os.WriteFile(filepath.Join(dir, "tokens", "personal.json"), []byte(`{}`), 0644)

		got := resolveAccount("")
		if got != "personal" {
			t.Errorf("resolveAccount('') = %q, want 'personal'", got)
		}
	})

	t.Run("first token file as fallback", func(t *testing.T) {
		dir := t.TempDir()
		configDir = dir
		tokensDir := filepath.Join(dir, "tokens")
		os.MkdirAll(tokensDir, 0755)
		os.WriteFile(filepath.Join(tokensDir, "shared.json"), []byte(`{}`), 0644)

		got := resolveAccount("")
		if got != "shared" {
			t.Errorf("resolveAccount('') = %q, want 'shared'", got)
		}
	})
}

func TestLoadToken(t *testing.T) {
	origDir := configDir
	defer func() { configDir = origDir }()

	dir := t.TempDir()
	configDir = dir
	tokensDir := filepath.Join(dir, "tokens")
	os.MkdirAll(tokensDir, 0755)

	td := tokenData{
		Email:        "test@example.com",
		Token:        "access123",
		RefreshToken: "refresh456",
		TokenURI:     "https://oauth2.googleapis.com/token",
		ClientID:     "client-id",
		ClientSecret: "client-secret",
		Expiry:       "2099-01-01T00:00:00Z",
	}
	data, _ := json.Marshal(td)
	os.WriteFile(filepath.Join(tokensDir, "test.json"), data, 0644)

	got := loadToken("test")
	if got.Email != "test@example.com" {
		t.Errorf("Email = %q, want 'test@example.com'", got.Email)
	}
	if got.Token != "access123" {
		t.Errorf("Token = %q, want 'access123'", got.Token)
	}
	if got.RefreshToken != "refresh456" {
		t.Errorf("RefreshToken = %q, want 'refresh456'", got.RefreshToken)
	}
}
