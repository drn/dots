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
echo -e "\033[0;32mInstalling vim-plug\033[0m"
mkdir -p $HOME/.vim/autoload
curl -fLo $HOME/.vim/autoload/plug.vim $vimplug
rm -f /tmp/vim-update-result
vim -c "PlugUpdate|set modifiable|4d|2d|2d|1d|execute line('$')|put=''|pu|w /tmp/vim-update-result|q|q|q|q"
cat /tmp/vim-update-result
rm -f /tmp/vim-update-result
