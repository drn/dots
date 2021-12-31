package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

var max = 100
var remote = baseRemote()
var dev = fmt.Sprintf("%s/dev", remote)
var master = fmt.Sprintf("%s/master", remote)

func main() {
	ancestors := ancestors()

	if len(ancestors) < 2 {
		os.Exit(1)
	}

	for _, ancestor := range ancestors[1:] {
		branches := branches(ancestor)
		if len(branches) == 0 {
			continue
		}

		identified := identify(branches)

		// if a branch is identified, use it
		if identified != "" {
			log.Info(identified)
			os.Exit(0)
		}
	}

	// no ancestor branch identified
	os.Exit(1)
}

func identify(branches []string) string {
	identified := ""

	for _, branch := range branches {
		branch = strings.TrimSpace(branch)
		// ignore HEAD
		if strings.Contains(branch, "HEAD") {
			continue
		}
		// ignore non-base remote branches
		if !strings.Contains(branch, fmt.Sprintf("%s/", remote)) {
			continue
		}
		// only update identified
		if identified == "" {
			identified = branch
		}
		// favor dev and master
		if branch == dev {
			return dev
		}
		if branch == master {
			return master
		}
	}

	return identified
}

func branches(sha string) []string {
	raw := run.Capture("git branch --remote --contains %s", sha)
	if raw == "" {
		return []string{}
	}
	return strings.Split(raw, "\n")
}

func ancestors() []string {
	history := run.Capture("git rev-list --max-count %d HEAD", max)
	return strings.Split(history, "\n")
}

// upstream if it exists, otherwise origin
func baseRemote() string {
	raw := run.Capture("git remote")
	remotes := strings.Split(raw, "\n")
	for _, remote := range remotes {
		if remote == "upstream" {
			return remote
		}
	}
	return "origin"
}
