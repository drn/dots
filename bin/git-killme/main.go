package main

import (
  "os"
  "strings"
  "github.com/drn/dots/git"
  "github.com/drn/dots/run"
  "github.com/drn/dots/log"
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

  prune("origin", branch)
  prune("upstream", branch)

  if branch == fallback { return }

  if !git.Checkout(fallback) { git.Create(fallback) }
  git.ResetHard(git.Ancestor())
  git.Delete(branch)
}

func prune(remote string, branch string) {
  if branch == "master" { return }
  if branch == "demo" { return }
  if branch == "staging" { return }
  if branch == "production" { return }

  if !git.RemoteHasBranch(remote, branch) { return}

  log.Info("Deleting %s from %s...", branch, remote)
  run.Verbose("git push %s :%s", remote, branch)
}
