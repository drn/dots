package main

import (
	"encoding/binary"
	"encoding/json"
	"net"
	"os"
	"path/filepath"
	"testing"
)

func TestSpeakViaDaemon_Success(t *testing.T) {
	sockPath := filepath.Join(t.TempDir(), "test.sock")
	origSock := daemonSock
	daemonSock = sockPath
	defer func() { daemonSock = origSock }()

	listener, err := net.Listen("unix", sockPath)
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()

	go func() {
		conn, _ := listener.Accept()
		defer conn.Close()

		buf := make([]byte, 4096)
		n, _ := conn.Read(buf)

		var req map[string]interface{}
		json.Unmarshal(buf[:n-1], &req)
		if req["text"] != "hello" {
			t.Errorf("daemon received text = %v, want %q", req["text"], "hello")
		}
		if req["voice"] != "af_heart" {
			t.Errorf("daemon received voice = %v, want %q", req["voice"], "af_heart")
		}

		fakeWav := []byte("RIFF-fake-wav")
		header := make([]byte, 5)
		header[0] = 0x00
		binary.BigEndian.PutUint32(header[1:], uint32(len(fakeWav)))
		conn.Write(header)
		conn.Write(fakeWav)
	}()

	outPath := filepath.Join(t.TempDir(), "out.wav")
	err = speakViaDaemon("hello", "af_heart", 1.0, outPath)
	if err != nil {
		t.Fatalf("speakViaDaemon returned error: %v", err)
	}

	data, err := os.ReadFile(outPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != "RIFF-fake-wav" {
		t.Errorf("output = %q, want %q", string(data), "RIFF-fake-wav")
	}
}

func TestSpeakViaDaemon_Error(t *testing.T) {
	sockPath := filepath.Join(t.TempDir(), "test.sock")
	origSock := daemonSock
	daemonSock = sockPath
	defer func() { daemonSock = origSock }()

	listener, err := net.Listen("unix", sockPath)
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()

	go func() {
		conn, _ := listener.Accept()
		defer conn.Close()

		buf := make([]byte, 4096)
		conn.Read(buf)

		errMsg := []byte("voice not found")
		header := make([]byte, 5)
		header[0] = 0x01
		binary.BigEndian.PutUint32(header[1:], uint32(len(errMsg)))
		conn.Write(header)
		conn.Write(errMsg)
	}()

	outPath := filepath.Join(t.TempDir(), "out.wav")
	err = speakViaDaemon("hello", "bad_voice", 1.0, outPath)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	if got := err.Error(); got != "kokoro daemon: voice not found" {
		t.Errorf("error = %q, want %q", got, "kokoro daemon: voice not found")
	}
}

func TestSpeakViaDaemon_NoDaemon(t *testing.T) {
	origSock := daemonSock
	daemonSock = "/tmp/nonexistent-kokoro-test.sock"
	defer func() { daemonSock = origSock }()

	err := speakViaDaemon("hello", "af_heart", 1.0, "/tmp/out.wav")
	if err == nil {
		t.Fatal("expected error when daemon not running, got nil")
	}
}
