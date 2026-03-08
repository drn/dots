// Bump the latest semver tag and create a new annotated git tag.
//
// Usage: version-update [patch|minor|major] [message]
//
// Defaults to patch bump. Finds the latest vX.Y.Z tag, increments the
// specified component, and creates an annotated git tag locally.
package main

import (
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

func main() {
	bump := "patch"
	message := ""

	if len(os.Args) >= 2 {
		bump = os.Args[1]
	}
	if len(os.Args) >= 3 {
		message = os.Args[2]
	}

	if bump != "patch" && bump != "minor" && bump != "major" {
		log.Error("Usage: version-update [patch|minor|major] [message]")
		os.Exit(1)
	}

	latest := latestTag()
	next := nextVersion(latest, bump)

	if latest == "" {
		log.Info("Updating from none to %s", next)
	} else {
		log.Info("Updating from %s to %s", latest, next)
	}

	if hasPackageJSON() {
		err := run.Verbose("npm version %s -m '%s'", strings.TrimPrefix(next, "v"), message)
		if err == nil {
			return
		}
		// fall back to git tag if npm version fails
	}

	err := run.Verbose("git tag -a %s -m '%s'", next, message)
	if err != nil {
		log.Error("Failed to create tag %s", next)
		os.Exit(1)
	}
}

func latestTag() string {
	raw := run.Capture("git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname")
	if raw == "" {
		return ""
	}
	tags := strings.Split(raw, "\n")

	// Parse and sort by semver to find the true latest
	type semver struct {
		tag                  string
		major, minor, patch int
	}
	var versions []semver
	for _, tag := range tags {
		v := strings.TrimPrefix(tag, "v")
		parts := strings.SplitN(v, ".", 3)
		if len(parts) != 3 {
			continue
		}
		major, e1 := strconv.Atoi(parts[0])
		minor, e2 := strconv.Atoi(parts[1])
		patch, e3 := strconv.Atoi(parts[2])
		if e1 != nil || e2 != nil || e3 != nil {
			continue
		}
		versions = append(versions, semver{tag, major, minor, patch})
	}

	if len(versions) == 0 {
		return ""
	}

	sort.Slice(versions, func(i, j int) bool {
		if versions[i].major != versions[j].major {
			return versions[i].major > versions[j].major
		}
		if versions[i].minor != versions[j].minor {
			return versions[i].minor > versions[j].minor
		}
		return versions[i].patch > versions[j].patch
	})

	return versions[0].tag
}

func nextVersion(latest string, bump string) string {
	if latest == "" {
		switch bump {
		case "major":
			return "v1.0.0"
		case "minor":
			return "v0.1.0"
		default:
			return "v0.0.1"
		}
	}

	v := strings.TrimPrefix(latest, "v")
	parts := strings.SplitN(v, ".", 3)
	major, _ := strconv.Atoi(parts[0])
	minor, _ := strconv.Atoi(parts[1])
	patch, _ := strconv.Atoi(parts[2])

	switch bump {
	case "major":
		return fmt.Sprintf("v%d.0.0", major+1)
	case "minor":
		return fmt.Sprintf("v%d.%d.0", major, minor+1)
	default:
		return fmt.Sprintf("v%d.%d.%d", major, minor, patch+1)
	}
}

func hasPackageJSON() bool {
	_, err := os.Stat("package.json")
	return err == nil
}
