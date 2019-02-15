package commands

import (
	"github.com/drn/dots/cli/commands/doctor"
	"github.com/spf13/cobra"
)

var cmdDoctor = &cobra.Command{
	Use:   "doctor",
	Short: "Runs system diagnostics",
	Run: func(cmd *cobra.Command, args []string) {
		doctor.Run()
	},
}
