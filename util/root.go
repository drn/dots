package util

import (
  "os"
  "os/exec"
)

// IsFileExists - Returns true if the specified file exists.
func IsFileExists(path string) bool {
  _, err := os.Stat(path)
  return !os.IsNotExist(err)
}

// IsCommand - Returns true if the specified command exists.
func IsCommand(command string) bool {
  _, err := exec.LookPath(command)
  return err == nil
}
