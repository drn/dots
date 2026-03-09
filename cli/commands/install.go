package commands

import (
	"os"

	"github.com/drn/dots/cli/commands/install"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

type component struct {
	Name        string
	Description string
	Alias       string
}

var components = []component{
	{"bin", "Installs ~/bin/* commands", ""},
	{"git", "Installs git extensions", ""},
	{"home", "Installs ~/.* config files", ""},
	{"zsh", "Installs zsh config files", ""},
	{"fonts", "Installs fonts", ""},
	{"homebrew", "Installs Homebrew dependencies", "brew"},
	{"npm", "Installs npm packages", ""},
	{"languages", "Installs asdf & languages", ""},
	{"vim", "Installs vim config", ""},
	{"hammerspoon", "Installs hammerspoon configuration", "hs"},
	{"osx", "Installs OSX configuration", ""},
	{"agents", "Installs agent skills (Claude Code + Codex)", ""},
}

func componentNames() []string {
	names := make([]string, len(components))
	for i, c := range components {
		names[i] = c.Name
	}
	return names
}

var cmdInstall = &cobra.Command{
	Use:   "install",
	Short: "Installs configuration",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) > 0 {
			cmd.Help()
			os.Exit(1)
		}

		items := append([]string{"all"}, componentNames()...)

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

	for _, c := range components {
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

	for _, name := range componentNames() {
		install.Call(name)
	}
}
