package install

import (
	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Git - Installs git configuration
func (i Install) Git() {
	log.Action("Install Git")
	link.Soft(
		path.FromDots("git/functions"),
		path.FromHome(".git-extensions"),
	)
}
