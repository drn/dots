package commands

import (
  "github.com/spf13/cobra"
  "github.com/drn/dots/cli/commands/cleanup"
)

var cmdCleanup = &cobra.Command{
  Use: "cleanup",
  Aliases: []string{ "clean" },
  Short: "Cleans legacy configuration",
  Run: func(cmd *cobra.Command, args []string) {
    cleanup.Run()
  },
}

