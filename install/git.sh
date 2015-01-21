#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# recreate git extensions directory
sudo rm -rf $HOME/.git-extensions
mkdir -p $HOME/.git-extensions

# install all git extensions
for location in $HOME/.dots/git/functions/*; do
  file="${location##*/}"
  link "$location" "$HOME/.git-extensions/$file"
done
