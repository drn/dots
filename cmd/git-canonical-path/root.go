package main

// Writes the canonical path to STDOUT

import (
	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/pkg/log"
)

func main() {
	log.Info("%s/%s", git.CanonicalRemote(), git.CanonicalBranch())
}
