// Package commands manages all top-level CLI commands
package commands

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var root = &cobra.Command{
	Use:   "dots",
	Short: "The dots CLI manages your development environment dependencies",
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Help()
	},
}

func addCommands() {
	root.AddCommand(cmdInstall)
	root.AddCommand(cmdUpdate)
	root.AddCommand(cmdClean)
	root.AddCommand(cmdDoctor)
	root.AddCommand(cmdSpinner)
	root.AddCommand(cmdDocker)
}

// Execute - Starts the CLI.
func Execute() {
	addCommands()

	if err := root.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(0)
	}
}
