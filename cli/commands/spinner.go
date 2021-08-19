package commands

import (
	"fmt"
	"time"

	spin "github.com/briandowns/spinner"
	"github.com/drn/dots/cli/commands/spinner"
	color "github.com/logrusorgru/aurora"
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
	cmdSpinner.AddCommand(cmdSpinnerCircles)
	cmdSpinner.AddCommand(cmdSpinnerConsole)
}

var cmdSpinnerBraille = &cobra.Command{
	Use:   "braille",
	Short: "Runs the braille spinner",
	Run: func(cmd *cobra.Command, args []string) {
		spinner.Braille()
	},
}

var cmdSpinnerCircles = &cobra.Command{
	Use:   "circles",
	Short: "Runs the circles spinner",
	Run: func(cmd *cobra.Command, args []string) {
		spinner.Circles()
	},
}

var cmdSpinnerDots = &cobra.Command{
	Use:   "dots",
	Short: "Runs the dots spinner",
	Run: func(cmd *cobra.Command, args []string) {
		spinner.Dots()
	},
}

var cmdSpinnerConsole = &cobra.Command{
	Use:   "console",
	Short: "Runs the console spinner",
	Run: func(cmd *cobra.Command, args []string) {
		s := spin.New(spin.CharSets[11], 75*time.Millisecond)
		s.Color("magenta")
		s.Prefix = fmt.Sprintf(
			"Running %s on %s (%s)... ",
			color.BrightCyan("console"),
			color.Blue("⬢ cluster"),
			color.BrightMagenta("env"),
		)
		s.Start()
		time.Sleep(2 * time.Second)
		s.Suffix = " connecting, run.3734 (...)"
		time.Sleep(2 * time.Second)
		s.Suffix = " up, run.3734 (...)"
		time.Sleep(2 * time.Second)
		s.Stop()
		fmt.Println(s.Prefix)
		fmt.Println("...")
	},
}
