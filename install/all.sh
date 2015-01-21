#!/bin/bash

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

# ensure dotfiles are up to date
sudo rm -rf $HOME/.dots
echo "Cloning drn/dotfiles to $HOME/.dots"
git clone git@github.com:drn/dotfiles.git $HOME/.dots --quiet

# install dotfiles
bash $HOME/.dots/install/dots.sh
# install terminal utilites
bash $HOME/.dots/install/utils.sh
# install node packages
bash $HOME/.dots/install/node.sh
# install bin files
bash $HOME/.dots/install/bin.sh
# install zsh configuration
bash $HOME/.dots/install/zsh.sh
# install git configuration
bash $HOME/.dots/install/git.sh
# install fonts
bash $HOME/.dots/install/fonts.sh
# install vim configuration
bash $HOME/.dots/install/vim.sh
# install os x configuration
bash $HOME/.dots/install/osx.sh
# install ubersicht widgets
bash $HOME/.dots/install/ubersicht.sh
