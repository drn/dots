#!/bin/bash
source "$HOME/.dots/install/core.cfg"

destination="$HOME/Library/Application Support/Übersicht/widgets"

# clean up destination directory
sudo rm -rf "$destination"
mkdir -p "$destination"

# install to ubersicht widgets directory
for location in $HOME/.dots/ubersicht/*; do
  file="${location##*/}"
  link "$location" "$destination/$file"
done
