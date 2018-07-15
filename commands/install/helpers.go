package install

import (
  "os"
  "fmt"
  "os/user"
  "github.com/drn/dots/log"
)

func link(from string, to string) {
  log.Info("Linking '$DOTS/%s' to '~/%s'", from, to)

  from = fmt.Sprintf("%s/%s", dotsPath(), from)
  to = fmt.Sprintf("%s/%s", homePath(), to)

  // overwrite existing symlinks
  if _, err := os.Lstat(to); err == nil {
    os.Remove(to)
  }

  // create symlink
  err := os.Symlink(from, to)

  // log errors
  if err != nil { log.Error(err.Error()) }
}

func dotsPath() string {
  return fmt.Sprintf("%s/go/src/github.com/drn/dots", homePath())
}

func homePath() string {
  user, _ := user.Current()
  return user.HomeDir
}
