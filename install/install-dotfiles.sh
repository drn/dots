#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
bin="/usr/local/bin"

if [[ -d "$dotfiles" ]]; then
  echo "Symlinking dotfiles from $dotfiles"
else
  echo "$dotfiles does not exist"
  exit 1
fi

# include install functions
source "$dotfiles/install/install.cfg"

# ~ files
for location in $dotfiles/home/*; do
  file="${location##*/}"
  file="${file%.*}"
  link "$location" "$HOME/.$file"
done

# bin files
for location in $dotfiles/bin/*; do
  file="${location##*/}"
  link "$location" "$bin/$file"
done
