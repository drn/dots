package install

import (
	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
)

// Bin - Symlinks ~/bin directory
func (i Install) Bin() {
	log.Action("Install Bin")
	link.Soft(
		path.FromDots("bin"),
		path.FromHome("bin"),
	)
}
