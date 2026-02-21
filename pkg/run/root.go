// Package run triggers system commands
package run

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/drn/dots/pkg/log"
)

// OSA - Runs the specified osascript command, capturing STDOUT and returning
// it as a string.
func OSA(command string, args ...interface{}) string {
	resolvedCommand := fmt.Sprintf(command, args...)
	return Capture("osascript -e '%s'", resolvedCommand)
}

// Capture - Runs the specified command, capturing STDOUT and returning it as a
// string. The exec error is logged as a warning if non-nil.
func Capture(command string, args ...interface{}) string {
	resolvedCommand := fmt.Sprintf(command, args...)
	out, err := exec.Command("zsh", "-c", resolvedCommand).CombinedOutput()
	if err != nil {
		log.Warning("Command failed: %s: %s", resolvedCommand, err.Error())
	}
	return strings.TrimSpace(string(out))
}

// Execute - Logs the specified command and runs it without escaping or
// suppressing STDOUT.
func Execute(command string) error {
	log.Raw(command)
	cmd := exec.Command("zsh", "-c", command)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// Verbose - Logs the specified command and runs it without suppressing STDOUT.
func Verbose(command string, args ...interface{}) error {
	resolvedCommand := fmt.Sprintf(command, args...)
	log.Command(resolvedCommand)
	cmd := exec.Command("zsh", "-c", resolvedCommand)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// Silent - Runs the specified command without suppressing STDOUT.
func Silent(command string, args ...interface{}) error {
	resolvedCommand := fmt.Sprintf(command, args...)
	cmd := exec.Command("zsh", "-c", resolvedCommand)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
