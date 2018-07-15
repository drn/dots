package commands

import (
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
}

var cmdInstallDots = &cobra.Command{
  Use: "dots",
  Short: "Installs ~/.* files",
  Run: func(cmd *cobra.Command, args []string) {
    color.Green("Installing ~/.* files...")
  },
}
