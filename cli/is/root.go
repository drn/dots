// Package is manages helper functions that return booleans
package is

import (
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// File - Returns true if the specified file exists.
func File(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

// Command - Returns true if the specified command exists.
func Command(command string) bool {
	_, err := exec.LookPath(command)
	return err == nil
}

// Tmux - Returns true if currently running tmux.
func Tmux() bool {
	if !strings.Contains(os.Getenv("TERM"), "screen") {
		return false
	}
	if os.Getenv("TMUX") == "" {
		return false
	}
	return true
}

// Osx - Returns true if operating system is OSX.
func Osx() bool {
	return runtime.GOOS == "darwin"
}
