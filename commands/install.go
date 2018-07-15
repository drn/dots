package commands

import (
  "os"
  "fmt"
  "os/user"
  "io/ioutil"
  "github.com/spf13/cobra"
  "github.com/fatih/color"
  "github.com/drn/dots/util"
)

var cmdInstall = &cobra.Command{
  Use: "install",
  Short: "Installs configuration",
  Run: func(cmd *cobra.Command, args []string) {
    cmd.Help()
  },
}

func init() {
  cmdInstall.AddCommand(cmdInstallBin)
  cmdInstall.AddCommand(cmdInstallGit)
  cmdInstall.AddCommand(cmdInstallHome)
  cmdInstall.AddCommand(cmdInstallHammerspoon)
}

var cmdInstallBin = &cobra.Command{
  Use: "bin",
  Short: "Installs ~/bin/* commands",
  Run: func(cmd *cobra.Command, args []string) {
    link("lib/bin", "bin")
  },
}

var cmdInstallGit = &cobra.Command{
  Use: "git",
  Short: "Installs git extensions",
  Run: func(cmd *cobra.Command, args []string) {
    link("lib/git/functions", ".git-extensions")
  },
}

var cmdInstallHome = &cobra.Command{
  Use: "home",
  Short: "Installs ~/.* config files",
  Run: func(cmd *cobra.Command, args []string) {
    color.Blue("Installing ~/.* files...")

    files, _ := ioutil.ReadDir(fmt.Sprintf("%s/lib/home", dotsPath()))
    for _, file := range files {
      link(
        fmt.Sprintf("lib/home/%s", file.Name()),
        fmt.Sprintf(".%s", file.Name()),
      )
    }
  },
}

var cmdInstallHammerspoon = &cobra.Command{
  Use: "hammerspoon",
  Aliases: []string{ "hs" },
  Short: "Installs hammerspoon configuration files",
  Run: func(cmd *cobra.Command, args []string) {
    link("lib/hammerspoon", ".hammerspoon")
    util.Osascript(
      "tell application \"%s\" to execute lua code \"%s\"",
      "Hammerspoon",
      "hs.reload()",
    )
  },
}

func link(from string, to string) {
  color.Blue("Linking '$DOTS/%s' to '~/%s'", from, to)

  from = fmt.Sprintf("%s/%s", dotsPath(), from)
  to = fmt.Sprintf("%s/%s", homePath(), to)

  // overwrite existing symlinks
  if _, err := os.Lstat(to); err == nil {
    os.Remove(to)
  }

  // create symlink
  err := os.Symlink(from, to)

  // log errors
  if err != nil { color.Red(err.Error()) }
}

func dotsPath() string {
  return fmt.Sprintf("%s/go/src/github.com/drn/dots", homePath())
}

func homePath() string {
  user, _ := user.Current()
  return user.HomeDir
}
