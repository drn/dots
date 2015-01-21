#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# install oh-my-zsh
sudo rm -rf $HOME/.oh-my-zsh
gitsync robbyrussell/oh-my-zsh $HOME/.oh-my-zsh

# install custom oh-my-zsh config files
for location in $HOME/.dots/zsh/*; do
  file="${location##*/}"
  link "$location" "$HOME/.oh-my-zsh/custom/$file"
done

# install zsh-syntax-highlighting
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
install_path="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
gitsync zsh-users/zsh-syntax-highlighting $install_path
