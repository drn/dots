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

type semver struct {
	tag                 string
	major, minor, patch int
}

func parseSemver(tag string) (semver, bool) {
	v := strings.TrimPrefix(tag, "v")
	parts := strings.SplitN(v, ".", 3)
	if len(parts) != 3 {
		return semver{}, false
	}
	major, e1 := strconv.Atoi(parts[0])
	minor, e2 := strconv.Atoi(parts[1])
	patch, e3 := strconv.Atoi(parts[2])
	if e1 != nil || e2 != nil || e3 != nil {
		return semver{}, false
	}
	return semver{tag, major, minor, patch}, true
}

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

	var versions []semver
	for _, tag := range strings.Split(raw, "\n") {
		if v, ok := parseSemver(tag); ok {
			versions = append(versions, v)
		}
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

	v, _ := parseSemver(latest)
	switch bump {
	case "major":
		return fmt.Sprintf("v%d.0.0", v.major+1)
	case "minor":
		return fmt.Sprintf("v%d.%d.0", v.major, v.minor+1)
	default:
		return fmt.Sprintf("v%d.%d.%d", v.major, v.minor, v.patch+1)
	}
}

func hasPackageJSON() bool {
	_, err := os.Stat("package.json")
	return err == nil
}
