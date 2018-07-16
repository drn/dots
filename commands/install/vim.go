package install

import (
  "fmt"
  "io/ioutil"
  "github.com/drn/dots/log"
  "github.com/drn/dots/path"
)

// Vim - Installs vim configuration
func Vim() {
  log.Action("Installing vim config")
  vimLinkConfig()
}

func vimLinkConfig() {
  files, _ := ioutil.ReadDir(fmt.Sprintf("%s/vim", path.Dots()))
  for _, file := range files {
    link(
      fmt.Sprintf("vim/%s", file.Name()),
      fmt.Sprintf(".vim/%s", file.Name()),
    )
  }
}
