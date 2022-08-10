// Resets hard to canonical remote & branch
package main

import (
	"os"

	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
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
