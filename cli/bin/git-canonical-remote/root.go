package main

// Writes the canonical remote to STDOUT

import (
	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/cli/log"
)

func main() {
	log.Info(git.CanonicalRemote())
}
