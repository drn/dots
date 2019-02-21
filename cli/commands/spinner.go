package commands

import (
	"github.com/drn/dots/cli/commands/spinner"
	"github.com/spf13/cobra"
)

var cmdSpinner = &cobra.Command{
	Use:   "spinner",
	Short: "Runs simple CLI spinners",
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Help()
	},
}

func init() {
	cmdSpinner.AddCommand(cmdSpinnerBraille)
	cmdSpinner.AddCommand(cmdSpinnerDots)
}

var cmdSpinnerBraille = &cobra.Command{
	Use:   "braille",
	Short: "Runs the braille spinner",
	Run: func(cmd *cobra.Command, args []string) {
		spinner.Braille()
	},
}

var cmdSpinnerDots = &cobra.Command{
	Use:   "dots",
	Short: "Runs the dots spinner",
	Run: func(cmd *cobra.Command, args []string) {
		spinner.Dots()
	},
}
