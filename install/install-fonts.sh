#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
fonts="$HOME/Library/Fonts"

if [[ -d "$dotfiles" ]]; then
  echo "Symlinking dotfiles from $dotfiles"
else
  echo "$dotfiles does not exist"
  exit 1
fi

# include install functions
source "$dotfiles/install/install.cfg"

# install fonts
for location in $dotfiles/fonts/*; do
  file="${location##*/}"
  echo "Copying $location to $font/$file"
  cp "$location" "$fonts/$file"
done
