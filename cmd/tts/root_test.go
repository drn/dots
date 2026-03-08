package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

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

func TestSpeak_Success(t *testing.T) {
	t.Setenv("OPENAI_API_KEY", "test-key")

	// Mock OpenAI API returning fake audio bytes
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

	// Use "true" as the play command (no-op success)
	origPlay := playCmd
	playCmd = "true"
	defer func() { playCmd = origPlay }()

	err := speak("test speech", "alloy", 1.4, "tts-1")
	if err != nil {
		t.Errorf("speak returned error: %v", err)
	}
}

func TestSpeak_APIError(t *testing.T) {
	t.Setenv("OPENAI_API_KEY", "test-key")

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"error": "invalid api key"}`))
	}))
	defer server.Close()

	origURL := apiURL
	apiURL = server.URL
	defer func() { apiURL = origURL }()

	err := speak("test", "alloy", 1.0, "tts-1")
	if err == nil {
		t.Fatal("expected error for 401 response, got nil")
	}
	if got := err.Error(); got != `OpenAI API error (401): {"error": "invalid api key"}` {
		t.Errorf("unexpected error message: %q", got)
	}
}

func TestSpeak_WritesAndCleansUpTempFile(t *testing.T) {
	t.Setenv("OPENAI_API_KEY", "test-key")

	audioData := "fake-mp3-content"
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(audioData))
	}))
	defer server.Close()

	origURL := apiURL
	apiURL = server.URL
	defer func() { apiURL = origURL }()

	// Use a script that captures the temp file path so we can verify cleanup
	origPlay := playCmd
	playCmd = "true"
	defer func() { playCmd = origPlay }()

	err := speak("test", "alloy", 1.0, "tts-1")
	if err != nil {
		t.Fatalf("speak returned error: %v", err)
	}

	// Verify temp files are cleaned up (no tts-*.mp3 in temp dir)
	matches, _ := os.ReadDir(os.TempDir())
	for _, m := range matches {
		if len(m.Name()) > 4 && m.Name()[:4] == "tts-" {
			t.Errorf("temp file not cleaned up: %s", m.Name())
		}
	}
}
