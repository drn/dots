package commands

import (
  "github.com/spf13/cobra"
  "github.com/drn/dots/cli/commands/doctor"
)

var cmdDoctor = &cobra.Command{
  Use: "doctor",
  Short: "Runs system diagnostics",
  Run: func(cmd *cobra.Command, args []string) {
    doctor.Run()
  },
}
