#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
bin="$HOME/bin"
ohmyzsh="$HOME/.oh-my-zsh"

# include install functions
source "$dotfiles/install/core.cfg"

# completely rebuild bin
sudo rm -rf $bin
mkdir -p $bin

# install all files in $dotfiles/bin to ~/bin
for location in $dotfiles/bin/*; do
  file="${location##*/}"
  link "$location" "$bin/$file"
done
