package commands

import (
	"github.com/drn/dots/cli/commands/doctor"
	"github.com/spf13/cobra"
)

var cmdDoctor = &cobra.Command{
	Use:   "doctor",
	Short: "Runs system diagnostics",
	Run: func(_ *cobra.Command, _ []string) {
		doctor.Run()
	},
}
