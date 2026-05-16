package install

import (
	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
)

// Fonts - Installs fonts
func Fonts() {
	log.Action("Install Fonts")
	linkDirEntries("fonts", "Library/Fonts/%s", link.Hard)
}
