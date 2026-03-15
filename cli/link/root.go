// Package link provides functions to create soft and hard links
package link

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Soft - Creates a soft link between input from and to arguments
func Soft(from string, to string) {
	create("Soft", from, to, os.Symlink)
}

// Hard - Creates a hard link between input from and to arguments
func Hard(from string, to string) {
	create("Hard", from, to, os.Link)
}

func create(label, from, to string, linkFn func(string, string) error) {
	log.Info("%s link: '%s' -> '%s'", label, path.Pretty(to), path.Pretty(from))
	removeExisting(to)
	if err := linkFn(from, to); err != nil {
		log.Error(err.Error())
	}
}

func removeExisting(linkPath string) {
	if _, err := os.Lstat(linkPath); err == nil {
		if err := os.Remove(linkPath); err != nil {
			log.Warning("Failed to remove existing link %s: %s", linkPath, err.Error())
		}
	}
}
