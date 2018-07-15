package util

import (
  "os"
)

// IsFileExists - Returns true if the specified file exists.
func IsFileExists(path string) bool {
  _, err := os.Stat(path)
  return !os.IsNotExist(err)
}
