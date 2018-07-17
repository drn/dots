package commands

import (
  "github.com/spf13/cobra"
  "github.com/drn/dots/commands/update"
)

var cmdUpdate = &cobra.Command{
  Use: "update",
  Aliases: []string{ "up" },
  Short: "Updates configuration",
  Run: func(cmd *cobra.Command, args []string) {
    update.Run()
  },
}
