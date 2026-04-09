package main

import (
	_ "embed"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
)

//go:embed serve.py
var daemonScript string

// daemonSock is the Unix socket path for the Kokoro TTS daemon, overridable for testing.
var daemonSock = "/tmp/kokoro-tts.sock"

// daemonPID is the PID file path for the Kokoro TTS daemon.
var daemonPID = "/tmp/kokoro-tts.pid"

// daemonLock is the lock file used to prevent concurrent daemon starts.
var daemonLock = "/tmp/kokoro-tts.start.lock"

// maxPayload is the maximum daemon response size (50 MB, well above any WAV).
const maxPayload = 50 << 20

// speakViaDaemon sends a TTS request to the running daemon and writes the WAV
// output to outPath. Returns an error if the daemon is not running or fails.
func speakViaDaemon(text, voice string, speed float64, outPath string) error {
	conn, err := net.Dial("unix", daemonSock)
	if err != nil {
		return err
	}
	defer conn.Close()

	req, _ := json.Marshal(map[string]interface{}{
		"text":  text,
		"voice": voice,
		"speed": speed,
	})
	req = append(req, '\n')
	if _, err := conn.Write(req); err != nil {
		return err
	}

	var header [5]byte
	if _, err := io.ReadFull(conn, header[:]); err != nil {
		return err
	}
	status := header[0]
	length := binary.BigEndian.Uint32(header[1:5])
	if length > maxPayload {
		return fmt.Errorf("kokoro daemon: response too large (%d bytes)", length)
	}
	payload := make([]byte, length)
	if _, err := io.ReadFull(conn, payload); err != nil {
		return err
	}

	if status != 0 {
		return fmt.Errorf("kokoro daemon: %s", string(payload))
	}

	return os.WriteFile(outPath, payload, 0644)
}

func startDaemon() error {
	if daemonRunning() {
		return fmt.Errorf("daemon already running (pid file: %s)", daemonPID)
	}
	return runDaemon(false)
}

func startDaemonBackground() error {
	// Acquire exclusive lock to prevent concurrent daemon starts.
	lf, err := os.OpenFile(daemonLock, os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return err
	}
	defer lf.Close()

	// Non-blocking lock — if another process holds it, skip.
	if err := syscall.Flock(int(lf.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		return nil // another process is already starting the daemon
	}
	defer syscall.Flock(int(lf.Fd()), syscall.LOCK_UN)

	// Check if daemon is already running.
	if daemonRunning() {
		return nil
	}

	return runDaemon(true)
}

// daemonRunning checks if the daemon process is alive via the PID file.
func daemonRunning() bool {
	data, err := os.ReadFile(daemonPID)
	if err != nil {
		return false
	}
	pid, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil {
		return false
	}
	proc, err := os.FindProcess(pid)
	if err != nil {
		return false
	}
	// Signal 0 checks if process exists without sending a signal.
	return proc.Signal(syscall.Signal(0)) == nil
}

func runDaemon(background bool) error {
	if !kokoroAvailable() {
		return fmt.Errorf(errNoVenv)
	}
	scriptPath := filepath.Join(filepath.Dir(kokoroPython), "..", "serve.py")
	// Only rewrite if content has changed to avoid unnecessary TOCTOU window.
	existing, err := os.ReadFile(scriptPath)
	if err != nil || string(existing) != daemonScript {
		if err := os.WriteFile(scriptPath, []byte(daemonScript), 0600); err != nil {
			return err
		}
	}
	cmd := exec.Command(kokoroPython, scriptPath)
	cmd.Env = append(os.Environ(), "PYTORCH_ENABLE_MPS_FALLBACK=1", "HF_HUB_OFFLINE=1")
	if background {
		cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
		return cmd.Start()
	}
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func stopDaemon() error {
	data, err := os.ReadFile(daemonPID)
	if err != nil {
		return fmt.Errorf("daemon not running (no PID file)")
	}
	pid, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil {
		return fmt.Errorf("invalid PID file: %w", err)
	}
	proc, err := os.FindProcess(pid)
	if err != nil {
		return err
	}
	return proc.Signal(syscall.SIGTERM)
}
