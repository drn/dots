package path

import (
  "fmt"
  "strings"
  "os/user"
)

// Pretty - Pretty prints the input path
func Pretty(path string) string {
  path = strings.Replace(path, Dots(), "$DOTS", 1)
  path = strings.Replace(path, Home(), "~", 1)
  return path
}

// Dots - Returns $DOTS path
func Dots() string {
  return fmt.Sprintf("%s/go/src/github.com/drn/dots", Home())
}

// FromDots - Returns path relative to $DOTS
func FromDots(path string, args ...interface{}) string {
  return fmt.Sprintf("%s/%s", Dots(), fmt.Sprintf(path, args...))
}

// Home - Returns $HOME path
func Home() string {
  user, _ := user.Current()
  return user.HomeDir
}

// FromHome - Returns path relative to $HOME
func FromHome(path string, args ...interface{}) string {
  return fmt.Sprintf("%s/%s", Home(), fmt.Sprintf(path, args...))
}
