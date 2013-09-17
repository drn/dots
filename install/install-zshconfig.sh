#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
ohmyzsh="$HOME/.oh-my-zsh"

# include install functions
source "$dotfiles/install/install.cfg"

# install oh-my-zsh
sudo rm -rf $ohmyzsh
clone git://github.com/robbyrussell/oh-my-zsh.git $ohmyzsh

# install custom oh-my-zsh config files
for location in $dotfiles/zsh/*; do
  file="${location##*/}"
  link "$location" "$ohmyzsh/custom/$file"
done

# install zsh-syntax-highlighting
mkdir -p "$ohmyzsh/custom/plugins"
clone git://github.com/zsh-users/zsh-syntax-highlighting.git "$ohmyzsh/custom/plugins/zsh-syntax-highlighting"
