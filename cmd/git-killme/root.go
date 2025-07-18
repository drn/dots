// `git killme`. Used to clean up the current working branch after active work
// on branch has finalized (merged or abandoned).
// Deletes the current branch from `origin` and `upstream` remotes. If the
// current branch is a protected branch, skip remote pruning. After remote
// pruning, checkout the default fallback branch (`root`), delete the local
// branch, and resets the fallback branch to the current ancestor commit.
package main

import (
	"os"
	"strings"

	"github.com/drn/dots/cli/git"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

var fallback = "root"

func main() {
	if !git.IsRepo() {
		log.Error("Aborting. Not in a git repository.")
		os.Exit(1)
	}

	if !strings.Contains(git.Status(), "nothing to commit") {
		log.Error("Aborting. Uncommitted data.")
		os.Exit(1)
	}

	branch := git.Branch()
	if branch == "" {
		log.Error("Aborting. No branches found.")
		os.Exit(1)
	}

	prune("origin", branch)
	prune("upstream", branch)

	currentBranch := git.Branch()
	if branch == currentBranch {
		if branch == fallback {
			return
		}
		if !git.Checkout(fallback) {
			git.Create(fallback)
		}

		git.ResetHard(git.Ancestor())
		git.Delete(branch)
	} else {
		log.Info(
			"Current branch %s does not match pruned branch %s.\n"+
				"Skipping fallback branch checkout and reset.",
			currentBranch,
			branch,
		)
		if currentBranch == fallback {
			return
		}
		git.Delete(branch)
	}
}

func prune(remote string, branch string) {
	protectedBranches := []string{
		"dev",
		"main",
		"master",
		"sandbox",
		"staging",
		"production",
		"ops-sandbox",
		"ops-staging",
		"ops-production",
	}
	for _, protectedBranch := range protectedBranches {
		if branch == protectedBranch {
			return
		}
	}

	if !git.RemoteHasBranch(remote, branch) {
		return
	}

	log.Info("Deleting %s from %s...", branch, remote)
	run.Verbose("git push %s :%s", remote, branch)
	run.Verbose("git remote prune %s", remote)
}
