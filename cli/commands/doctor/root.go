package doctor

import (
	"fmt"
	"os"
	"strings"

	"github.com/drn/dots/cli/is"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

// Run - Runs diagnostic commands
func Run() {
	log.Action("Running system diagnostics")
	tools()
	shell()
	homebrew()
}

func tools() {
	if run.Silent("xcode-select --print-path >/dev/null") {
		log.Success("Xcode Command Line Tools are properly installed")
	} else {
		log.Error("Xcode Command Line Tools are not installed")
		resolve([]string{"xcode-select --install"})
	}
}

func shell() {
	if os.Getenv("SHELL") == "/usr/local/bin/zsh" {
		log.Success("ZSH is the default shell")
	} else {
		log.Error("ZSH is not the default shell")
		resolve([]string{
			"brew install zsh",
			"sudo dscl . -create $HOME UserShell /usr/local/bin/zsh",
		})
	}
}

func homebrew() {
	if is.Command("brew") {
		log.Success("Homebrew is installed")
	} else {
		log.Error("Homebrew is not installed")
		command := fmt.Sprintf(
			"/usr/bin/ruby -e \"(curl -fsSL %s)\"",
			"https://raw.githubusercontent.com/Homebrew/install/master/install",
		)
		resolve([]string{command})
	}
}

func resolve(resolution []string) {
	log.Warning("Resolution:\n  %s\n\n", strings.Join(resolution, "\n  "))
}
