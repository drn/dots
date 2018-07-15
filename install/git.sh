#!/bin/bash
source "$DOTS/install/core.cfg"

# recreate git extensions directory
sudo rm -rf $HOME/.git-extensions
mkdir -p $HOME/.git-extensions

# install all git extensions
for location in $DOTS/lib/git/functions/*; do
  file="${location##*/}"
  link "$location" "$HOME/.git-extensions/$file"
done
