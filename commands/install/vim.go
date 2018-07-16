package install

import (
  "fmt"
  "strings"
  "io/ioutil"
  "github.com/drn/dots/log"
  "github.com/drn/dots/path"
  "github.com/drn/dots/util"
)

// Vim - Installs vim configuration
func Vim() {
  log.Action("Installing vim config")
  vimLinkConfig()
  vimUpdatePlugins()
}

func vimLinkConfig() {
  log.Info("Ensuring all vim configuration is linked:")
  files, _ := ioutil.ReadDir(fmt.Sprintf("%s/lib/vim", path.Dots()))
  for _, file := range files {
    link(
      fmt.Sprintf("lib/vim/%s", file.Name()),
      fmt.Sprintf(".vim/%s", file.Name()),
    )
  }
}

func vimUpdatePlugins() {
  log.Info("Updating vim plugins:")
  util.Run(
    "nvim -c \"%s\"",
    strings.Join(
      []string{
        "PlugUpdate",
        "set modifiable",
        "4d", "2d", "2d", "1d",
        "execute line('$')",
        "put=''", "pu",
        "w /tmp/vim-update-result",
        "q", "q", "q", "q",
      },
      "|",
    ),
  )
  bytes, err := ioutil.ReadFile("/tmp/vim-update-result")
  if err == nil { fmt.Println(string(bytes)) }
}
