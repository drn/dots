package tmux

import (
  "github.com/drn/dots/is"
  "github.com/drn/dots/run"
)

// Window - Returns tmux window name
func Window() string {
  if !is.Tmux() { return "" }
  return run.Capture("tmux display-message -p '#W'")
}

// SetWindow - Sets tmux window name
func SetWindow(name string) {
  if !is.Tmux() || name == "" { return }
  run.Capture("tmux rename-window %s", name)
}
