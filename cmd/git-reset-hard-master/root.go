package main

// Resets hard to canonical remote & branch

import (
	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/run"
	"os"
)

func main() {
	remote := git.CanonicalRemote()
	branch := git.CanonicalBranch()

	if remote == "" {
		log.Error("Neither `upstream` or `origin` exist in this repository.")
		os.Exit(1)
	}

	run.Verbose("git reset --hard %s/%s", remote, branch)
}
