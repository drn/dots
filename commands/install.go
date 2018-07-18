package commands

import (
  "os"
  "github.com/spf13/cobra"
  "github.com/manifoldco/promptui"
  "github.com/drn/dots/commands/install"
)

var commands = []map[string]string{
  map[string]string{
    "command": "all",
    "description": "Runs all install scripts",
  },
  map[string]string{
    "command": "bin",
    "description": "Installs ~/bin/* commands",
  },
  map[string]string{
    "command": "git",
    "description": "Installs git extensions",
  },
  map[string]string{
    "command": "home",
    "description": "Installs ~/.* config files",
  },
  map[string]string{
    "command": "zsh",
    "description": "Installs zsh config files",
  },
  map[string]string{
    "command":"fonts",
    "description": "Installs fonts",
  },
  map[string]string{
    "command":"homebrew",
    "description": "Installs Homebrew dependencies",
    "alias": "brew",
  },
  map[string]string{
    "command":"npm",
    "description": "Installs npm packages",
  },
  map[string]string{
    "command":"ruby",
    "description": "Installs Ruby",
  },
  map[string]string{
    "command":"python",
    "description": "Installs Python",
  },
  map[string]string{
    "command":"vim",
    "description": "Installs vim config",
  },
  map[string]string{
    "command":"hammerspoon",
    "description": "Installs hammerspoon configuration",
    "alias": "hs",
  },
  map[string]string{
    "command":"osx",
    "description": "Installs OSX configuration",
  },
}

var cmdInstall = &cobra.Command{
  Use: "install",
  Short: "Installs configuration",
  Run: func(cmd *cobra.Command, args []string) {
    if len(args) > 0 {
      cmd.Help()
      os.Exit(1)
    }

    items := make([]string, len(commands))
    i := 0
    for _, command := range commands {
      items[i] = command["command"]
      i++
    }

    prompt := promptui.Select{
      Label: "Select component to install",
      Items: items,
    }
    _, result, err := prompt.Run()

    if err != nil { os.Exit(1) }

    install.Call(result)
  },
}

func init() {
  for _, command := range commands {
    var aliases []string
    if alias, ok := command["alias"]; ok {
      aliases = []string{alias}
    } else {
      aliases = []string{}
    }
    cmd := &cobra.Command{
      Use: command["command"],
      Aliases: aliases,
      Short: command["description"],
      Run: func(cmd *cobra.Command, args []string) {
        install.Call(cmd.Use)
      },
    }
    cmdInstall.AddCommand(cmd)
  }
}
