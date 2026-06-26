// Package commands manages all top-level CLI commands
package commands

import (
	"fmt"
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/spf13/cobra"
)

var (
	verbose bool
	quiet   bool
)

var root = &cobra.Command{
	Use:   "dots",
	Short: "The dots CLI manages your development environment dependencies",
	PersistentPreRun: func(_ *cobra.Command, _ []string) {
		// --quiet takes precedence over --verbose when both are set.
		switch {
		case quiet:
			log.SetLevel(log.LevelQuiet)
		case verbose:
			log.SetLevel(log.LevelVerbose)
		default:
			log.SetLevel(log.LevelNormal)
		}
	},
	Run: func(cmd *cobra.Command, _ []string) {
		_ = cmd.Help()
	},
}

func addCommands() {
	root.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "Enable verbose output")
	root.PersistentFlags().BoolVarP(&quiet, "quiet", "q", false, "Suppress informational output")

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
		os.Exit(1)
	}
}
