package install

import (
	"os"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Home - Symlinks ~/.* configuration
func (i Install) Home() {
	log.Action("Install Home")

	files, err := os.ReadDir(path.FromDots("home"))
	if err != nil {
		log.Warning("Failed to read home directory: %s", err.Error())
		return
	}
	for _, file := range files {
		link.Soft(
			path.FromDots("home/%s", file.Name()),
			path.FromHome(".%s", file.Name()),
		)
	}
}
