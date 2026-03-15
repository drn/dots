package commands

import (
	"os"

	"github.com/drn/dots/cli/commands/install"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

var cmdInstall = &cobra.Command{
	Use:   "install",
	Short: "Installs configuration",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) > 0 {
			_ = cmd.Help()
			os.Exit(1)
		}

		components := install.Components()
		names := make([]string, len(components))
		for i, c := range components {
			names[i] = c.Name
		}
		items := append([]string{"all"}, names...)

		prompt := promptui.Select{
			Label: "Select component to install",
			Items: items,
		}
		_, result, err := prompt.Run()

		if err != nil {
			os.Exit(1)
		}

		if result == "all" {
			installAll()
		} else {
			install.Call(result)
		}
	},
}

func init() {
	cmdInstall.AddCommand(
		&cobra.Command{
			Use:   "all",
			Short: "Runs all install scripts",
			Run: func(_ *cobra.Command, _ []string) {
				installAll()
			},
		},
	)

	for _, c := range install.Components() {
		var aliases []string
		if c.Alias != "" {
			aliases = []string{c.Alias}
		}
		cmd := &cobra.Command{
			Use:     c.Name,
			Aliases: aliases,
			Short:   c.Description,
			Run: func(cmd *cobra.Command, _ []string) {
				install.Call(cmd.Use)
			},
		}
		cmdInstall.AddCommand(cmd)
	}
}

func installAll() {
	log.Action("Running all install scripts...")

	log.Info("Ensuring sudo access")
	command := "sudo -p \"Enter your password: \" echo \"We're good to go!\""
	if err := run.Silent(command); err != nil {
		os.Exit(1)
	}

	for _, c := range install.Components() {
		install.Call(c.Name)
	}
}
