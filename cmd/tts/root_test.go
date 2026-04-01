package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

func stubMic(active bool) func() {
	orig := micActive
	micActive = func() bool { return active }
	return func() { micActive = orig }
}

func TestEnsureVoiceCached_SkipsWhenPresent(t *testing.T) {
	dir := t.TempDir()
	snap := filepath.Join(dir, "abc123", "voices")
	os.MkdirAll(snap, 0755)
	os.WriteFile(filepath.Join(snap, "af_heart.pt"), []byte("fake"), 0644)

	orig := hfCacheDir
	hfCacheDir = dir
	defer func() { hfCacheDir = orig }()

	// Should return immediately without calling Python
	origPython := kokoroPython
	kokoroPython = "false" // would fail if called
	defer func() { kokoroPython = origPython }()

	ensureVoiceCached("af_heart") // no error = success
}

func TestEnsureVoiceCached_DownloadsWhenMissing(t *testing.T) {
	dir := t.TempDir()

	orig := hfCacheDir
	hfCacheDir = dir
	defer func() { hfCacheDir = orig }()

	// Use a script that creates a marker file to prove it was called
	marker := filepath.Join(dir, "download-called")
	origPython := kokoroPython
	kokoroPython = "bash"
	defer func() { kokoroPython = origPython }()

	// bash -c "touch <marker>" won't match, so use a wrapper script
	script := filepath.Join(dir, "fake-python")
	os.WriteFile(script, []byte("#!/bin/bash\ntouch "+marker+"\n"), 0755)
	kokoroPython = script

	ensureVoiceCached("af_alloy")

	if _, err := os.Stat(marker); os.IsNotExist(err) {
		t.Error("expected download command to be invoked, but marker file not created")
	}
}

func TestEnsureVoiceCached_RejectsInvalidVoice(_ *testing.T) {
	origPython := kokoroPython
	kokoroPython = "false" // would fail if called
	defer func() { kokoroPython = origPython }()

	// Should return early without calling Python for invalid names
	ensureVoiceCached("'; import os; os.system('whoami') #")
	ensureVoiceCached("../../../etc/passwd")
	ensureVoiceCached("")
}

func TestResolveVoice(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"heart", "af_heart"},
		{"alloy", "af_alloy"},
		{"echo", "am_echo"},
		{"fable", "bm_fable"},
		{"nova", "af_nova"},
		{"onyx", "am_onyx"},
		{"shimmer", "af_sky"},
		{"ash", "am_adam"},
		{"coral", "af_bella"},
		{"sage", "am_michael"},
		{"bella", "af_bella"},
		{"sky", "af_sky"},
		{"af_heart", "af_heart"},
		{"am_michael", "am_michael"},
	}
	for _, tt := range tests {
		if got := resolveVoice(tt.input); got != tt.want {
			t.Errorf("resolveVoice(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestBuildRequest_PayloadFields(t *testing.T) {
	t.Setenv("OPENAI_API_KEY", "test-key")

	req, err := buildRequest("hello world", "nova", "tts-1-hd", 1.5)
	if err != nil {
		t.Fatalf("buildRequest returned error: %v", err)
	}

	if req.Method != "POST" {
		t.Errorf("method = %q, want POST", req.Method)
	}
	if req.URL.String() != apiURL {
		t.Errorf("url = %q, want %q", req.URL.String(), apiURL)
	}
	if got := req.Header.Get("Authorization"); got != "Bearer test-key" {
		t.Errorf("Authorization = %q, want %q", got, "Bearer test-key")
	}
	if got := req.Header.Get("Content-Type"); got != "application/json" {
		t.Errorf("Content-Type = %q, want %q", got, "application/json")
	}

	body, _ := io.ReadAll(req.Body)
	var payload map[string]interface{}
	if err := json.Unmarshal(body, &payload); err != nil {
		t.Fatalf("failed to parse request body: %v", err)
	}

	if payload["input"] != "hello world" {
		t.Errorf("input = %v, want %q", payload["input"], "hello world")
	}
	if payload["voice"] != "nova" {
		t.Errorf("voice = %v, want %q", payload["voice"], "nova")
	}
	if payload["model"] != "tts-1-hd" {
		t.Errorf("model = %v, want %q", payload["model"], "tts-1-hd")
	}
	if payload["speed"] != 1.5 {
		t.Errorf("speed = %v, want 1.5", payload["speed"])
	}
	if payload["response_format"] != "mp3" {
		t.Errorf("response_format = %v, want %q", payload["response_format"], "mp3")
	}
}

func TestSpeakLocal_SkipsWhenMicActive(t *testing.T) {
	defer stubMic(true)()

	err := speakLocal("test", "af_heart", 1.0)
	if err != nil {
		t.Errorf("expected nil error when mic active, got: %v", err)
	}
}

func TestSpeakLocal_Success(t *testing.T) {
	defer stubMic(false)()

	origPython := kokoroPython
	kokoroPython = "true"
	defer func() { kokoroPython = origPython }()

	origPlay := playCmd
	playCmd = "true"
	defer func() { playCmd = origPlay }()

	err := speakLocal("test speech", "af_heart", 1.0)
	if err != nil {
		t.Errorf("speakLocal returned error: %v", err)
	}
}

func TestSpeakRemote_SkipsWhenMicActive(t *testing.T) {
	defer stubMic(true)()

	err := speakRemote("test", "alloy", 1.0, "tts-1")
	if err != nil {
		t.Errorf("expected nil error when mic active, got: %v", err)
	}
}

func TestSpeakRemote_Success(t *testing.T) {
	t.Setenv("OPENAI_API_KEY", "test-key")
	defer stubMic(false)()

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		var payload map[string]interface{}
		json.Unmarshal(body, &payload)

		if payload["input"] != "test speech" {
			t.Errorf("server received input = %v, want %q", payload["input"], "test speech")
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte("fake-audio-data"))
	}))
	defer server.Close()

	origURL := apiURL
	apiURL = server.URL
	defer func() { apiURL = origURL }()

	origPlay := playCmd
	playCmd = "true"
	defer func() { playCmd = origPlay }()

	err := speakRemote("test speech", "alloy", 1.4, "tts-1")
	if err != nil {
		t.Errorf("speakRemote returned error: %v", err)
	}
}

func TestSpeakRemote_APIError(t *testing.T) {
	t.Setenv("OPENAI_API_KEY", "test-key")
	defer stubMic(false)()

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"error": "invalid api key"}`))
	}))
	defer server.Close()

	origURL := apiURL
	apiURL = server.URL
	defer func() { apiURL = origURL }()

	err := speakRemote("test", "alloy", 1.0, "tts-1")
	if err == nil {
		t.Fatal("expected error for 401 response, got nil")
	}
	if got := err.Error(); got != `OpenAI API error (401): {"error": "invalid api key"}` {
		t.Errorf("unexpected error message: %q", got)
	}
}

func TestSpeakRemote_WritesAndCleansUpTempFile(t *testing.T) {
	t.Setenv("OPENAI_API_KEY", "test-key")
	defer stubMic(false)()

	tmpDir := t.TempDir()
	t.Setenv("TMPDIR", tmpDir)

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("fake-mp3-content"))
	}))
	defer server.Close()

	origURL := apiURL
	apiURL = server.URL
	defer func() { apiURL = origURL }()

	origPlay := playCmd
	playCmd = "true"
	defer func() { playCmd = origPlay }()

	err := speakRemote("test", "alloy", 1.0, "tts-1")
	if err != nil {
		t.Fatalf("speakRemote returned error: %v", err)
	}

	matches, _ := os.ReadDir(tmpDir)
	for _, m := range matches {
		if len(m.Name()) > 4 && m.Name()[:4] == "tts-" {
			t.Errorf("temp file not cleaned up: %s", m.Name())
		}
	}
}
