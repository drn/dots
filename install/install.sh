#!/bin/bash

# set up default development directory
dev="$HOME/Development"
dotfiles="$dev/dotfiles"

# set zsh as default shell
chsh -s /bin/zsh
# create default directory structure
mkdir -p $dev $dev/personal $dev/work $dev/opensource
# ensure dotfiles is up to date
rm -rf $dotfiles
echo "Cloning darrenli/dotfiles to $dotfiles"
git clone git@github.com:darrenli/dotfiles.git $dotfiles --quiet
# install dotfiles
sudo bash $dotfiles/install/install-dotfiles.sh
# install gitconfig
sudo bash $dotfiles/install/install-gitconfig.sh
# install vim configuration
sudo bash $dotfiles/install/install-vimconfig.sh
# install zsh configuration
sudo bash $dotfiles/install/install-zshconfig.sh
# install fonts
sudo bash $dotfiles/install/install-fonts.sh
