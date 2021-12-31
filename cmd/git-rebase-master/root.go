package main

// Rebase on top of the canonical path

import (
	"os"
	"strings"

	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/pkg/run"
)

func main() {
	run.Verbose(
		"git rebase %s/%s %s",
		git.CanonicalRemote(),
		git.CanonicalBranch(),
		strings.Join(os.Args[1:], " "),
	)
}
