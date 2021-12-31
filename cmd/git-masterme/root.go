package main

// Pushes the current branch to the canonical remote's canonical branch

import (
	"os"
	"strings"

	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/run"
)

func main() {
	branch := git.Branch()
	path := []string{
		git.CanonicalRemote(),
		git.CanonicalBranch(),
	}

	log.Info(
		"Attempting to push local %s to %s/%s...",
		branch,
		path[0],
		path[1],
	)

	run.Verbose(
		"git push %s %s:%s %s",
		path[0],
		branch,
		path[1],
		strings.Join(os.Args[1:], " "),
	)
}
