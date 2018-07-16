package path

import (
  "fmt"
  "os/user"
)

// Dots - Returns $DOTS path
func Dots() string {
  return fmt.Sprintf("%s/go/src/github.com/drn/dots", Home())
}

// Home - Returns $HOME path
func Home() string {
  user, _ := user.Current()
  return user.HomeDir
}
