#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
gitfunc="$dotfiles/git/functions"
githome="$HOME/.git-extensions"

# include install functions
source "$dotfiles/install/install.cfg"

# recreate git extensions directory
sudo rm -rf $githome
mkdir $githome

# install all git extensions
for location in $gitfunc/*; do
  file="${location##*/}"
  link "$location" "$githome/$file"
done
