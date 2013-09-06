#!/bin/bash

# set up default development directory
dev="$HOME/Development"
dotfiles="$dev/dotfiles"

# set zsh as default shell
chsh -s /bin/zsh
# create default directory
mkdir -p $dev
# ensure dotfiles is up to date
rm -rf $dotfiles
git clone git@github.com:darrenli/dotfiles.git $dotfiles
# install dotfiles
sudo bash $dotfiles/install/install-dotfiles.sh
# install vim configuration
sudo bash $dotfiles/install/install-vimconfig.sh
# install zsh configuration
sudo bash $dotfiles/install/install-zshconfig.sh
