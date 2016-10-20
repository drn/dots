#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# delete /etc/zprofile - added by os x 10.11
# path_helper conflicts - http://www.zsh.org/mla/users/2015/msg00727.html
sudo rm -f /etc/zprofile

if which brew >/dev/null 2>&1; then
  brew untap getantibody/homebrew-antibody || true
  brew tap getantibody/homebrew-antibody
  brew install antibody
else
  curl -sL https://git.io/vwMNi | sh -s
fi

antibody bundle < "$HOME/.dots/zsh/bundles" > ~/.bundles
