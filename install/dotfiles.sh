#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"

# include install functions
source "$dotfiles/install/core.cfg"

# ~ files
for location in $dotfiles/home/*; do
  file="${location##*/}"
  echo "$location to $HOME/.$file"
  link "$location" "$HOME/.$file"
done
