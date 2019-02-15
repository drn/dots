package commands

import (
	"github.com/drn/dots/cli/commands/cleanup"
	"github.com/spf13/cobra"
)

var cmdCleanup = &cobra.Command{
	Use:     "cleanup",
	Aliases: []string{"clean"},
	Short:   "Cleans legacy configuration",
	Run: func(cmd *cobra.Command, args []string) {
		cleanup.Run()
	},
}
