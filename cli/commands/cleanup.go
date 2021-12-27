package commands

import (
	"github.com/drn/dots/cli/commands/clean"
	"github.com/spf13/cobra"
)

var cmdClean = &cobra.Command{
	Use:   "clean",
	Short: "Cleans legacy configuration",
	Run: func(cmd *cobra.Command, args []string) {
		clean.Run()
	},
}
