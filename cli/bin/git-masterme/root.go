package main

// Pushes the current branch to the primary remote's master branch

import (
	"os"
	"strings"

	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/run"
)

func main() {
	branch := git.Branch()
	remote := git.Remote()

	log.Info(
		"Attempting to push local %s to %s/master...",
		branch,
		remote,
	)

	run.Verbose(
		"git push %s %s:master %s",
		remote,
		branch,
		strings.Join(os.Args[1:], " "),
	)
}
