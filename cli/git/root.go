package git

import (
	"fmt"
	"strings"

	"github.com/drn/dots/cli/run"
)

// IsRepo - Returns true if currently in a git repository
func IsRepo() bool {
	return run.Silent("git rev-parse --git-dir >/dev/null 2>&1")
}

// Branch - Returns the current HEAD alias
func Branch() string {
	branch := run.Capture("git rev-parse --abbrev-ref HEAD")
	if strings.Contains(branch, "fatal") {
		return ""
	}
	return branch
}

// Remote - Returns the primary git remote
func Remote() string {
	if strings.Contains(Branch(), "upstream") {
		return "upstream"
	}
	return "origin"
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
	)
}

// Checkout - Checks out the specified branch
func Checkout(branch string) bool {
	return run.Verbose("git checkout %s 2>/dev/null", branch)
}

// Create - Creates the specified branch
func Create(branch string) bool {
	return run.Verbose(
		"git checkout %s 2>/dev/null || git checkout -b %s",
		branch, branch,
	)
}

// ResetHard - Hard resets to the specified address
func ResetHard(address string) {
	run.Verbose("git reset --hard %s", address)
}

// Delete - Deletes the specified branch
func Delete(branch string) bool {
	return run.Verbose("git branch -D %s", branch)
}

// Ancestor - Returns the ancestor of HEAD
func Ancestor() string {
	return run.Capture("git ancestor")
}
