#!/bin/bash

# set up default development directory
dev="$HOME/Development"
dotfiles="$dev/dotfiles"

echo "Installing SanguineRane configuration for $(whoami)"

# ensure sudo access
sudo -p "Enter your password: " echo "We're good to go!"
if [ $? -ne 0 ]; then exit 1; fi

# change directory to home, in order to avoid directory conflicts
cd ~

# ensure updated zsh is the default shell
echo "Ensuring ZSH is the default shell"

# if homebrew is installed
if hash brew 2>/dev/null; then

  # if homebrew zsh is not the current shell
  brewpath="$(which brew | sed 's/\/brew//')"
  if [ "$SHELL" != "$brewpath/zsh" ]; then

    # install zsh if not already installed
    if [ -z "$(brew list | grep zsh)" ]; then
      echo "Installing ZSH via Homebrew"
      brew install zsh
    fi

    # include homebrew zsh path in /etc/shells
    if [ -z "$(grep -irn "$brewpath/zsh" /etc/shells)" ]; then
      echo "Whitelisting Homebrew installed ZSH"
      sudo -s "echo '$brewpath/zsh' >> /etc/shells"
    fi

    # change shell to homebrew zsh
    echo "Changing shell to homebrew installed zsh"
    chsh -s $brewpath/zsh
  fi
else
  # fallback to system zsh and display warning
  echo "Warning: Homebrew not found. Cannot install updated zsh version. Falling back to system zsh."
  chsh -s /bin/zsh
fi

# create default directory structure
echo "Ensuring expected directory hierarchy is in place."
mkdir -p $dev $dev/personal $dev/work $dev/opensource
# ensure dotfiles is up to date
sudo rm -rf $dotfiles
echo "Cloning drn/dotfiles to $dotfiles"
git clone git@github.com:drn/dotfiles.git $dotfiles --quiet

# install dotfiles
bash $dotfiles/install/dots.sh
# install terminal utilites
bash $dotfiles/install/utils.sh
# install node packages
bash $dotfiles/install/node.sh
# install bin files
bash $dotfiles/install/bin.sh
# install zsh configuration
bash $dotfiles/install/zsh.sh
# install git configuration
bash $dotfiles/install/git.sh
# install fonts
bash $dotfiles/install/fonts.sh
# install vim configuration
bash $dotfiles/install/vim.sh
# install os x configuration
bash $dotfiles/install/osx.sh
# install ubersicht widgets
bash $dotfiles/install/ubersicht.sh
