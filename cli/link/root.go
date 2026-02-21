// Package link provides functions to create soft and hard links
package link

import (
	"os"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Soft - Creates a soft link between input from and to arguments
func Soft(from string, to string) {
	log.Info("Soft link: '%s' -> '%s'", path.Pretty(to), path.Pretty(from))

	removeExisting(to)

	// create soft link
	err := os.Symlink(from, to)

	// log errors
	if err != nil {
		log.Error(err.Error())
	}
}

// Hard - Creates a hard link between input from and to arguments
func Hard(from string, to string) {
	log.Info("Hard link: '%s' -> '%s'", path.Pretty(to), path.Pretty(from))

	removeExisting(to)

	// create hard link
	err := os.Link(from, to)

	// log errors
	if err != nil {
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
