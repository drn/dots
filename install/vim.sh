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

# ensure neovim directories exist
mkdir -p ${XDG_CONFIG_HOME:=$HOME/.config}
ln -shfF $vim $XDG_CONFIG_HOME/nvim
ln -shfF $HOME/.vimrc $XDG_CONFIG_HOME/nvim/init.vim

# install vim-plug and bundles
echo -e "\033[0;32mInstalling vim-plug\033[0m"
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs $vimplug
rm -f /tmp/vim-update-result

echo -e "\033[0;32mUpdating vim plugins\033[0m"
vim -c "PlugUpdate|set modifiable|4d|2d|2d|1d|execute line('$')|put=''|pu|w /tmp/vim-update-result|q|q|q|q"
cat /tmp/vim-update-result
rm -f /tmp/vim-update-result

echo -e "\033[0;32mCleaning unused vim plugins\033[0m"
vim -c "PlugClean!|set modifiable|w /tmp/vim-update-result|q|q|q|q"
cat /tmp/vim-update-result
rm -f /tmp/vim-update-result
