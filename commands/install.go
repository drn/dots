package commands

import (
  "os"
  "fmt"
  "os/user"
  "github.com/spf13/cobra"
  "github.com/fatih/color"
)

var cmdInstall = &cobra.Command{
  Use: "install",
  Short: "Installs configuration",
  Run: func(cmd *cobra.Command, args []string) {
    cmd.Help()
  },
}

func init() {
  cmdInstall.AddCommand(cmdInstallDots)
  cmdInstall.AddCommand(cmdInstallHammerspoon)
}

var cmdInstallDots = &cobra.Command{
  Use: "dots",
  Short: "Installs ~/.* files",
  Run: func(cmd *cobra.Command, args []string) {
    color.Green("Installing ~/.* files...")
  },
}

var cmdInstallHammerspoon = &cobra.Command{
  Use: "hammerspoon",
  Aliases: []string{ "hs" },
  Short: "Installs hammerspoon configuration files",
  Run: func(cmd *cobra.Command, args []string) {
    link("lib/hammerspoon", ".hammerspoon")
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
