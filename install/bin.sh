#!/bin/bash
source "$DOTS/install/core.cfg"

# completely rebuild bin
sudo rm -rf $HOME/bin
mkdir -p $HOME/bin
for location in $DOTS/bin/*; do
  file="${location##*/}"
  link "$location" "$HOME/bin/$file"
done
