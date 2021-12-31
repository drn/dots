package main

// Writes the canonical branch to STDOUT

import (
	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/pkg/log"
)

func main() {
	log.Info(git.CanonicalBranch())
}
