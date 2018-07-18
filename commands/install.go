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
        "homebrew",
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
    case "home":
      install.Home()
    case "zsh":
      install.Zsh()
    case "homebrew":
      install.Homebrew()
    case "bin":
      install.Bin()
    case "git":
      install.Git()
    case "vim":
      install.Vim()
    case "fonts":
      install.Fonts()
    case "ruby":
      install.Ruby()
    case "npm":
      install.Npm()
    case "osx":
      install.Osx()
    case "hammerspoon":
      install.Hammerspoon()
    }
  },
}

func init() {
  cmdInstall.AddCommand(cmdInstallAll)
  cmdInstall.AddCommand(cmdInstallHome)
  cmdInstall.AddCommand(cmdInstallZsh)
  cmdInstall.AddCommand(cmdInstallHomebrew)
  cmdInstall.AddCommand(cmdInstallBin)
  cmdInstall.AddCommand(cmdInstallGit)
  cmdInstall.AddCommand(cmdInstallVim)
  cmdInstall.AddCommand(cmdInstallFonts)
  cmdInstall.AddCommand(cmdInstallRuby)
  cmdInstall.AddCommand(cmdInstallNpm)
  cmdInstall.AddCommand(cmdInstallOsx)
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

var cmdInstallHomebrew = &cobra.Command{
  Use: "homebrew",
  Aliases: []string{ "brew" },
  Short: "Installs Homebrew dependencies",
  Run: func(cmd *cobra.Command, args []string) {
    install.Homebrew()
  },
}

var cmdInstallNpm = &cobra.Command{
  Use: "npm",
  Short: "Installs npm packages",
  Run: func(cmd *cobra.Command, args []string) {
    install.Npm()
  },
}

var cmdInstallRuby = &cobra.Command{
  Use: "ruby",
  Short: "Installs Ruby",
  Run: func(cmd *cobra.Command, args []string) {
    install.Ruby()
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
