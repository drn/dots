#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"

# include install functions
source "$dotfiles/install/install.cfg"

# ~ files
for location in $dotfiles/home/*; do
  file="${location##*/}"
  file="${file%.*}"
  link "$location" "$HOME/.$file"
done
