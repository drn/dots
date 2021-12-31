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
// string.
func Capture(command string, args ...interface{}) string {
	resolvedCommand := fmt.Sprintf(command, args...)
	out, _ := exec.Command("sh", "-c", resolvedCommand).CombinedOutput()
	return strings.TrimSpace(string(out))
}

// Execute - Logs the specified command and runs it without escaping or
// suppressing STDOUT.
func Execute(command string) bool {
	log.Raw(command)
	cmd := exec.Command("bash", "-c", command)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	return err == nil
}

// Verbose - Logs the specified command and runs it without suppressing STDOUT.
func Verbose(command string, args ...interface{}) bool {
	resolvedCommand := fmt.Sprintf(command, args...)
	log.Command(resolvedCommand)
	cmd := exec.Command("bash", "-c", resolvedCommand)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	return err == nil
}

// Silent - Runs the specified command without suppressing STDOUT.
func Silent(command string, args ...interface{}) bool {
	resolvedCommand := fmt.Sprintf(command, args...)
	cmd := exec.Command("bash", "-c", resolvedCommand)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	return err == nil
}
