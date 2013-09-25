#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
ohmyzsh="$HOME/.oh-my-zsh"

# include install functions
source "$dotfiles/install/install.cfg"

# install oh-my-zsh
sudo rm -rf $ohmyzsh
clone robbyrussell/oh-my-zsh $ohmyzsh

# install custom oh-my-zsh config files
for location in $dotfiles/zsh/*; do
  file="${location##*/}"
  link "$location" "$ohmyzsh/custom/$file"
done

# install zsh-syntax-highlighting
mkdir -p "$ohmyzsh/custom/plugins"
clone zsh-users/zsh-syntax-highlighting "$ohmyzsh/custom/plugins/zsh-syntax-highlighting"
