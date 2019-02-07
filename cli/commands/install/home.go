package install

import (
  "fmt"
  "io/ioutil"
  "github.com/drn/dots/cli/log"
  "github.com/drn/dots/cli/link"
  "github.com/drn/dots/cli/path"
)

// Home - Symlinks ~/.* configuration
func (i Install) Home() {
  log.Action("Install Home")

  files, _ := ioutil.ReadDir(fmt.Sprintf("%s/home", path.Dots()))
  for _, file := range files {
    link.Soft(
      path.FromDots("home/%s", file.Name()),
      path.FromHome(".%s", file.Name()),
    )
  }
}
