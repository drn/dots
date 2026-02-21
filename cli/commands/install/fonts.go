package install

import (
	"os"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Fonts - Installs fonts
func (i Install) Fonts() {
	log.Action("Install Fonts")

	files, err := os.ReadDir(path.FromDots("fonts"))
	if err != nil {
		log.Warning("Failed to read fonts directory: %s", err.Error())
		return
	}
	for _, file := range files {
		link.Hard(
			path.FromDots("fonts/%s", file.Name()),
			path.FromHome("Library/Fonts/%s", file.Name()),
		)
	}
}
