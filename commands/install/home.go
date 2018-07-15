package install

import (
  "fmt"
  "io/ioutil"
  "github.com/fatih/color"
)

// Home - Symlinks ~/.* configuration
func Home() {
  color.Blue("Installing ~/.* files...")

  files, _ := ioutil.ReadDir(fmt.Sprintf("%s/lib/home", dotsPath()))
  for _, file := range files {
    link(
      fmt.Sprintf("lib/home/%s", file.Name()),
      fmt.Sprintf(".%s", file.Name()),
    )
  }
}
