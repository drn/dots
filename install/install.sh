#!/bin/bash

# set up default development directory
dev="$HOME/Development"
dotfiles="$dev/dotfiles"

echo "Running script as $(whoami)"

# set zsh as default shell
echo "Setting ZSH as default shell"
chsh -s /bin/zsh
# create default directory structure
echo "Ensuring expected directory hierarchy is in place."
mkdir -p $dev $dev/personal $dev/work $dev/opensource
# ensure dotfiles is up to date
sudo rm -rf $dotfiles
echo "Cloning darrenli/dotfiles to $dotfiles"
git clone git@github.com:darrenli/dotfiles.git $dotfiles --quiet
# install dotfiles
bash $dotfiles/install/install-dotfiles.sh
# install gitconfig
bash $dotfiles/install/install-gitconfig.sh
# install vim configuration
bash $dotfiles/install/install-vimconfig.sh
# install zsh configuration
bash $dotfiles/install/install-zshconfig.sh
# install fonts
bash $dotfiles/install/install-fonts.sh
# install basic configuration
bash $dotfiles/install/install-config.sh
