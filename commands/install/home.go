package install

import (
  "fmt"
  "io/ioutil"
  "github.com/drn/dots/log"
  "github.com/drn/dots/link"
  "github.com/drn/dots/path"
)

// Home - Symlinks ~/.* configuration
func Home() {
  log.Action("Install Home")

  files, _ := ioutil.ReadDir(fmt.Sprintf("%s/lib/home", path.Dots()))
  for _, file := range files {
    link.Soft(
      path.FromDots("lib/home/%s", file.Name()),
      path.FromHome(".%s", file.Name()),
    )
  }
}
