#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
ohmyzsh="$HOME/.oh-my-zsh"

# include install functions
source "$dotfiles/install/core.cfg"

# install oh-my-zsh
sudo rm -rf $ohmyzsh
gitsync robbyrussell/oh-my-zsh $ohmyzsh

# install custom oh-my-zsh config files
for location in $dotfiles/zsh/*; do
  file="${location##*/}"
  link "$location" "$ohmyzsh/custom/$file"
done

# install zsh-syntax-highlighting
mkdir -p "$ohmyzsh/custom/plugins"
gitsync zsh-users/zsh-syntax-highlighting "$ohmyzsh/custom/plugins/zsh-syntax-highlighting"
