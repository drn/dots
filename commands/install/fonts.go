package install

import (
  "fmt"
  "io/ioutil"
  "github.com/drn/dots/log"
  "github.com/drn/dots/link"
  "github.com/drn/dots/path"
)

// Fonts - Installs fonts
func Fonts() {
  log.Action("Install Fonts")

  files, _ := ioutil.ReadDir(fmt.Sprintf("%s/lib/fonts", path.Dots()))
  for _, file := range files {
    link.Hard(
      path.FromDots("lib/fonts/%s", file.Name()),
      path.FromHome("Library/Fonts/%s", file.Name()),
    )
  }
}
