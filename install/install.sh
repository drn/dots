#!/bin/bash

# set up default development directory
dev="$HOME/Development"

# set zsh as default shell
chsh -s /bin/zsh
# create default directory
mkdir $dev
# clones dotfiles
git clone git@github.com:darrenli/dotfiles.git "$dev/dotfiles"
# install dotfiles
sudo bash $dev/install/install-dotfiles.sh
# install vim configuration
sudo bash $dev/install/install-vim.sh
# install zsh configuration
sudo bash $dev/install/install-zshconfig.sh
