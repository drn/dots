// Package commands manages all top-level CLI commands
package commands

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// Verbose controls whether verbose output is enabled
var Verbose bool

// Quiet controls whether output is suppressed
var Quiet bool

var root = &cobra.Command{
	Use:   "dots",
	Short: "The dots CLI manages your development environment dependencies",
	Run: func(cmd *cobra.Command, _ []string) {
		cmd.Help()
	},
}

func init() {
	root.PersistentFlags().BoolVarP(&Verbose, "verbose", "v", false, "enable verbose output")
	root.PersistentFlags().BoolVarP(&Quiet, "quiet", "q", false, "suppress output")
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
