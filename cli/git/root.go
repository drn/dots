// Package git provides git-releated helper functions
package git

import (
	"fmt"
	"slices"
	"strings"

	"github.com/drn/dots/pkg/run"
)

// IsRepo - Returns true if currently in a git repository
func IsRepo() bool {
	return run.Silent("git rev-parse --git-dir >/dev/null 2>&1") == nil
}

// Branch - Returns the current HEAD alias
func Branch() string {
	branch := run.Capture("git rev-parse --abbrev-ref HEAD")
	if strings.Contains(branch, "fatal") {
		return ""
	}
	return branch
}

// RemoteBranches - Returns a slice of the current remote branches
func RemoteBranches() []string {
	branches := strings.Fields(run.Capture("git branch --remote"))
	return filterBranches(branches)
}

func filterBranches(branches []string) []string {
	return slices.DeleteFunc(branches, func(branch string) bool {
		switch branch {
		case "->", "origin/HEAD", "upstream/HEAD":
			return true
		default:
			return false
		}
	})
}

// Remotes - Returns the configured remotes
func Remotes() []string {
	return strings.Fields(run.Capture("git remote"))
}

// CanonicalRemote - Returns the canonical git remote
func CanonicalRemote() string {
	remotes := Remotes()
	options := []string{"upstream", "origin"}
	for _, option := range options {
		for _, remote := range remotes {
			if remote == option {
				return option
			}
		}
	}
	return ""
}

// CanonicalBranch - Returns the canonical git remote
func CanonicalBranch() string {
	remote := CanonicalRemote()
	if remote == "" {
		return ""
	}
	match := fmt.Sprintf("%s/main", remote)
	for _, branch := range RemoteBranches() {
		if branch == match {
			return "main"
		}
	}
	return "master"
}

// Status - Returns the current status
func Status() string {
	return run.Capture("git status")
}

// RemoteHasBranch - Returns true if specified remote contains the specified
// branch
func RemoteHasBranch(remote string, branch string) bool {
	return run.Silent(
		"git branch --remote --contains %s >/dev/null 2>&1",
		fmt.Sprintf("%s/%s", remote, branch),
	) == nil
}

// Checkout - Checks out the specified branch
func Checkout(branch string) bool {
	return run.Verbose("git checkout %s 2>/dev/null", branch) == nil
}

// Create - Creates the specified branch
func Create(branch string) bool {
	return run.Verbose(
		"git checkout %s 2>/dev/null || git checkout -b %s",
		branch, branch,
	) == nil
}

// ResetHard - Hard resets to the specified address
func ResetHard(address string) {
	run.Verbose("git reset --hard %s", address)
}

// Delete - Deletes the specified branch
func Delete(branch string) bool {
	return run.Verbose("git branch -D %s", branch) == nil
}

// Ancestor - Returns the ancestor of HEAD
func Ancestor() string {
	return run.Capture("git ancestor")
}
