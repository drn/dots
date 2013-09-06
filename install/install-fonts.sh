#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
fonts="$HOME/Library/Fonts"

# include install functions
source "$dotfiles/install/install.cfg"

# install fonts
for location in $dotfiles/fonts/*; do
  file="${location##*/}"
  echo "Copying $location to $font/$file"
  cp -f "$location" "$fonts/$file"
done
