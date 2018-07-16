package install

import (
  "os"
  "fmt"
  "github.com/drn/dots/log"
  "github.com/drn/dots/path"
)

func hardlink(from string, to string) {
  log.Info("Hard linking '$DOTS/%s' to '~/%s'", from, to)

  from = fmt.Sprintf("%s/%s", path.Dots(), from)
  to = fmt.Sprintf("%s/%s", path.Home(), to)

  // overwrite existing links
  if _, err := os.Lstat(to); err == nil {
    os.Remove(to)
  }

  // create link
  err := os.Link(from, to)

  // log errors
  if err != nil { log.Error(err.Error()) }
}

func link(from string, to string) {
  log.Info("Linking '$DOTS/%s' to '~/%s'", from, to)

  from = fmt.Sprintf("%s/%s", path.Dots(), from)
  to = fmt.Sprintf("%s/%s", path.Home(), to)

  // overwrite existing symlinks
  if _, err := os.Lstat(to); err == nil {
    os.Remove(to)
  }

  // create symlink
  err := os.Symlink(from, to)

  // log errors
  if err != nil { log.Error(err.Error()) }
}
