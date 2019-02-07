package install

import (
  "fmt"
  "io/ioutil"
  "github.com/drn/dots/cli/log"
  "github.com/drn/dots/cli/link"
  "github.com/drn/dots/cli/path"
)

// Fonts - Installs fonts
func (i Install) Fonts() {
  log.Action("Install Fonts")

  files, _ := ioutil.ReadDir(fmt.Sprintf("%s/fonts", path.Dots()))
  for _, file := range files {
    link.Hard(
      path.FromDots("fonts/%s", file.Name()),
      path.FromHome("Library/Fonts/%s", file.Name()),
    )
  }
}
