// Writes the canonical remote to STDOUT
package main

import (
	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/pkg/log"
)

func main() {
	log.Info(git.CanonicalRemote())
}
