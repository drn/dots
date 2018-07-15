#!/bin/bash
source "$DOTS/install/core.cfg"

# delete /etc/zprofile - added by os x 10.11
# path_helper conflicts - http://www.zsh.org/mla/users/2015/msg00727.html
sudo rm -f /etc/zprofile

if which brew >/dev/null 2>&1; then
  brew install getantibody/tap/antibody
else
  curl -sL https://git.io/vwMNi | sh -s
fi

antibody bundle < "$DOTS/zsh/bundles" > ~/.bundles
