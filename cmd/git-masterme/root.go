// Pushes the current branch to the canonical remote's canonical branch
package main

import (
	"os"
	"strings"

	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
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

	if err := run.Verbose(
		"git push %s %s:%s %s",
		path[0],
		branch,
		path[1],
		strings.Join(os.Args[1:], " "),
	); err != nil {
		os.Exit(1)
	}
}
