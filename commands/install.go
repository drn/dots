package commands

import (
  "os"
  "github.com/spf13/cobra"
  "github.com/manifoldco/promptui"
  "github.com/drn/dots/commands/install"
)

var cmdInstall = &cobra.Command{
  Use: "install",
  Short: "Installs configuration",
  Run: func(cmd *cobra.Command, args []string) {
    prompt := promptui.Select{
      Label: "Select component to install",
      Items: []string{
        "all",
        "bin",
        "git",
        "home",
        "zsh",
        "fonts",
        "hammerspoon",
      },
    }
    _, result, err := prompt.Run()

    if err != nil { os.Exit(1) }

    switch result {
    case "all":
      install.All()
    case "bin":
      install.Bin()
    case "git":
      install.Git()
    case "home":
      install.Home()
    case "zsh":
      install.Zsh()
    case "fonts":
      install.Fonts()
    case "hammerspoon":
      install.Hammerspoon()
    }
  },
}

func init() {
  cmdInstall.AddCommand(cmdInstallAll)
  cmdInstall.AddCommand(cmdInstallBin)
  cmdInstall.AddCommand(cmdInstallGit)
  cmdInstall.AddCommand(cmdInstallHome)
  cmdInstall.AddCommand(cmdInstallZsh)
  cmdInstall.AddCommand(cmdInstallFonts)
  cmdInstall.AddCommand(cmdInstallHammerspoon)
}

var cmdInstallAll = &cobra.Command{
  Use: "all",
  Short: "Runs all install scripts",
  Run: func(cmd *cobra.Command, args []string) {
    install.All()
  },
}

var cmdInstallBin = &cobra.Command{
  Use: "bin",
  Short: "Installs ~/bin/* commands",
  Run: func(cmd *cobra.Command, args []string) {
    install.Bin()
  },
}

var cmdInstallGit = &cobra.Command{
  Use: "git",
  Short: "Installs git extensions",
  Run: func(cmd *cobra.Command, args []string) {
    install.Git()
  },
}

var cmdInstallHome = &cobra.Command{
  Use: "home",
  Short: "Installs ~/.* config files",
  Run: func(cmd *cobra.Command, args []string) {
    install.Home()
  },
}

var cmdInstallZsh = &cobra.Command{
  Use: "zsh",
  Short: "Installs zsh config files",
  Run: func(cmd *cobra.Command, args []string) {
    install.Zsh()
  },
}

var cmdInstallFonts = &cobra.Command{
  Use: "fonts",
  Short: "Installs fonts",
  Run: func(cmd *cobra.Command, args []string) {
    install.Fonts()
  },
}

var cmdInstallHammerspoon = &cobra.Command{
  Use: "hammerspoon",
  Aliases: []string{ "hs" },
  Short: "Installs hammerspoon configuration files",
  Run: func(cmd *cobra.Command, args []string) {
    install.Hammerspoon()
  },
}
