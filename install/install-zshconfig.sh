#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
ohmyzsh="$HOME/.oh-my-zsh"

if [[ -d "$dotfiles" ]]; then
  echo "Symlinking dotfiles from $dotfiles"
else
  echo "$dotfiles does not exist"
  exit 1
fi

# include install functions
source "$dotfiles/install/install.cfg"

# install oh-my-zsh
rm -rf $ohmyzsh
git clone git://github.com/robbyrussell/oh-my-zsh.git $ohmyzsh

cd $dotfiles
for location in $dotfiles/zsh-custom/*.*; do
  file="${location##*/}"
  file="${file%.*}"
  link "$location" "$ohmyzsh/custom"
done

# install zsh-syntax-highlighting
mkdir -p "$ohmyzsh/custom/plugins"
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git "$ohmyzsh/custom/plugins/zsh-syntax-highlighting"
