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
        "npm",
        "vim",
        "hammerspoon",
        "osx",
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
    case "npm":
      install.Npm()
    case "vim":
      install.Vim()
    case "hammerspoon":
      install.Hammerspoon()
    case "osx":
      install.Osx()
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
  cmdInstall.AddCommand(cmdInstallNpm)
  cmdInstall.AddCommand(cmdInstallVim)
  cmdInstall.AddCommand(cmdInstallHammerspoon)
  cmdInstall.AddCommand(cmdInstallOsx)
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

var cmdInstallNpm = &cobra.Command{
  Use: "npm",
  Short: "Installs npm packages",
  Run: func(cmd *cobra.Command, args []string) {
    install.Npm()
  },
}

var cmdInstallVim = &cobra.Command{
  Use: "vim",
  Short: "Installs vim config",
  Run: func(cmd *cobra.Command, args []string) {
    install.Vim()
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

var cmdInstallOsx = &cobra.Command{
  Use: "osx",
  Short: "Installs OSX configuration",
  Run: func(cmd *cobra.Command, args []string) {
    install.Osx()
  },
}
