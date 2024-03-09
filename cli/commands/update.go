package commands

import (
	"github.com/drn/dots/cli/commands/update"
	"github.com/spf13/cobra"
)

var cmdUpdate = &cobra.Command{
	Use:     "update",
	Aliases: []string{"up"},
	Short:   "Updates configuration",
	Run: func(_ *cobra.Command, _ []string) {
		update.Run()
	},
}
