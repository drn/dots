#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# delete /etc/zprofile - added by os x 10.11
# path_helper conflicts - http://www.zsh.org/mla/users/2015/msg00727.html
sudo rm -f /etc/zprofile

# install oh-my-zsh
sudo rm -rf $HOME/.oh-my-zsh
gitsync robbyrussell/oh-my-zsh $HOME/.oh-my-zsh

# install custom oh-my-zsh config files
for location in $HOME/.dots/zsh/*; do
  file="${location##*/}"
  link "$location" "$HOME/.oh-my-zsh/custom/$file"
done

# install zsh plugins
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"

# install zsh-syntax-highlighting
install_path="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
gitsync zsh-users/zsh-syntax-highlighting $install_path

# install zsh-autosuggestions
install_path="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
gitsync zsh-users/zsh-autosuggestions $install_path
