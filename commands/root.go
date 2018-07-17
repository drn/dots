package commands

import (
  "fmt"
  "os"
  "github.com/spf13/cobra"
)

var root = &cobra.Command{
  Use:   "dots",
  Short: "The dots CLI manages your development environment dependencies",
  Run:   func(cmd *cobra.Command, args []string) {
    cmd.Help()
  },
}

func addCommands() {
  root.AddCommand(cmdInstall)
  root.AddCommand(cmdUpdate)
  root.AddCommand(cmdCleanup)
}

// Execute - Starts the CLI.
func Execute() {
  addCommands()

  if err := root.Execute(); err != nil {
    fmt.Println(err)
    os.Exit(0)
  }
}
