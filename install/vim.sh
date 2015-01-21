#!/bin/bash
source "$HOME/.dots/install/core.cfg"

vim="$HOME/.vim"
vimplug="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

# destroy all vim directories
files=(
  "$vim/after",
  "$vim/ftplugin",
  "$vim/mappings",
  "$vim/plugin"
)
for directory in "${directories[@]}"; do
  rm -rf $directory
done

# recursively link all vim configuration files
echo -e "\033[0;32mLinking all vim configuration files...\033[0m"
rlink $HOME/.dots/vim $vim

# install vim-plug and bundles
echo "Installing vim-plug"
curl -fLo $HOME/.vim/autoload/plug.vim $vimplug
vim -c 'PlugUpdate|q|q|q|q'
