#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
mjolnir="$dotfiles/mjolnir"
destination="$HOME/.mjolnir"

# include install functions
source "$dotfiles/install/core.cfg"

# clean up destination directory
sudo rm -rf "$destination"
mkdir -p "$destination"

# install all files in $dotfiles/ubersicht to ubersicht widgets directory
for location in $mjolnir/*; do
  file="${location##*/}"
  link "$location" "$destination/$file"
done
