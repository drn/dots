package install

import (
	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
)

// Home - Symlinks ~/.* configuration
func Home() {
	log.Action("Install Home")
	linkDirEntries("home", ".%s", link.Soft)
}
