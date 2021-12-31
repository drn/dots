package install

import (
	"io/ioutil"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Home - Symlinks ~/.* configuration
func (i Install) Home() {
	log.Action("Install Home")

	files, _ := ioutil.ReadDir(path.FromDots("home"))
	for _, file := range files {
		link.Soft(
			path.FromDots("home/%s", file.Name()),
			path.FromHome(".%s", file.Name()),
		)
	}
}
