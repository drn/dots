package commands

import (
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
	"github.com/spf13/cobra"
)

var cmdDocker = &cobra.Command{
	Use:     "docker",
	Aliases: []string{"dock"},
	Short:   "Docker command aliases",
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Help()
	},
}

func init() {
	cmdDocker.AddCommand(cmdDockerStopAll)
}

var cmdDockerStopAll = &cobra.Command{
	Use:     "stop-all",
	Aliases: []string{"stop"},
	Short:   "Stops all running docker containers",
	Run: func(cmd *cobra.Command, args []string) {
		log.Info("Stopping all running docker containers")
		run.Verbose("docker stop $(docker ps -a -q)")
	},
}
