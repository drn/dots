package util

import (
  "os"
  "fmt"
  "strings"
  "os/exec"
  "github.com/drn/dots/log"
)

// IsCommand - Returns true if the specified command exists.
func IsCommand(command string) bool {
  _, err := exec.LookPath(command)
  return err == nil
}

// Osascript - Runs the specified osascript command, suppressing STDOUT and
// returning it as a string.
func Osascript(command string, args ...interface{}) string {
  resolvedCommand := fmt.Sprintf(command, args...)
  return Exec("osascript -e '%s'", resolvedCommand)
}

// Exec - Runs the specified command, suppressing STDOUT and returning it as a
// string.
func Exec(command string, args ...interface{}) string {
  resolvedCommand := fmt.Sprintf(command, args...)
  out, _ := exec.Command("sh", "-c", resolvedCommand).CombinedOutput()
  return strings.TrimSpace(string(out))
}

// Run - Logs the specified command and runs it without suppressing STDOUT.
func Run(command string, args ...interface{}) {
  resolvedCommand := fmt.Sprintf(command, args...)
  log.Command(resolvedCommand)
  cmd := exec.Command("bash", "-c", resolvedCommand)
  cmd.Stdout = os.Stdout
  cmd.Stderr = os.Stderr
  cmd.Run()
}

// RunSilent - Runs the specified command without suppressing STDOUT.
func RunSilent(command string, args ...interface{}) {
  resolvedCommand := fmt.Sprintf(command, args...)
  cmd := exec.Command("bash", "-c", resolvedCommand)
  cmd.Stdout = os.Stdout
  cmd.Stderr = os.Stderr
  cmd.Run()
}
