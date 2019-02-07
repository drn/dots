package link

import (
  "os"
  "github.com/drn/dots/cli/log"
  "github.com/drn/dots/cli/path"
)

// Soft - Creates a soft link between input from and to arguments
func Soft(from string, to string) {
  log.Info("Soft linking '%s' to '%s'", path.Pretty(from), path.Pretty(to))

  removeExisting(to)

  // create soft link
  err := os.Symlink(from, to)

  // log errors
  if err != nil { log.Error(err.Error()) }
}

// Hard - Creates a hard link between input from and to arguments
func Hard(from string, to string) {
  log.Info("Hard linking '%s' to '%s'", path.Pretty(from), path.Pretty(to))

  removeExisting(to)

  // create hard link
  err := os.Link(from, to)

  // log errors
  if err != nil { log.Error(err.Error()) }
}

func removeExisting(linkPath string) {
  if _, err := os.Lstat(linkPath); err == nil {
    os.Remove(linkPath)
  }
}
