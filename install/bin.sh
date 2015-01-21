#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# completely rebuild bin
sudo rm -rf $HOME/bin
mkdir -p $HOME/bin
for location in $HOME/.dots/bin/*; do
  file="${location##*/}"
  link "$location" "$HOME/bin/$file"
done
