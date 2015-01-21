#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
vimsource="$dotfiles/vim"
vim="$HOME/.vim"
vimfile="$dotfiles/Vimfile"

# include install functions
source "$dotfiles/install/core.cfg"

# remove all quickly-built directories
rm -rf $vim/ftplugin $vim/plugin

# if not updateonly, destroy ~/.vim/bundles hierarchy
if ! $updateonly; then
  rm -rf $vim/bundle $vim/autoload
fi

# ensure non-bundle ~/.vim hierarchy
mkdir -p $vim/autoload $vim/ftplugin $vim/plugin/settings

# recursively link all vim configuration files
echo -e "\033[0;32mLinking all vim configuration files...\033[0m"
rlink $vimsource $vim

# install vim-plug and bundles
echo "Installing vim-plug"
curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim -c 'PlugUpdate|q|q|q|q'
