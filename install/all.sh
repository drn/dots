#!/bin/bash

echo "Installing SanguineRane configuration for $(whoami)"

# ensure sudo access
sudo -p "Enter your password: " echo "We're good to go!"
if [ $? -ne 0 ]; then exit 1; fi

# change directory to home, in order to avoid directory conflicts
cd

# ensure command line tools are installed
echo "Ensuring OS X Command Line Tools are installed"
xcode-select --install 2>/dev/null || true

# ensure updated zsh is the default shell
echo "Ensuring ZSH is the default shell"

# ensure homebrew is installed
if ! hash brew 2>/dev/null; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# if homebrew zsh is not the current shell
if [ "$SHELL" != "/usr/local/bin/zsh" ]; then

  # install zsh if not already installed
  if [ -z "$(brew list | grep zsh)" ]; then
    echo "Installing ZSH via Homebrew"
    brew install zsh
  fi

  # change shell to homebrew zsh
  echo "Changing shell to homebrew installed zsh"
  sudo dscl . -create $HOME UserShell /usr/local/bin/zsh
  # chsh -s $brewpath/zsh
fi

# directory setup
mkdir -p $HOME/Development

# ensure dotfiles are up to date
echo "Cloning drn/dots to $HOME/.dots"
if ! git clone https://github.com/drn/dots.git $HOME/.dots --quiet; then
  cd $HOME/.dots
  git remote rename origin upstream 2>/dev/null
  git fetch
  git reset --hard upstream/master
  cd
fi

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
# install hammerspoon config
bash $HOME/.dots/install/hammerspoon.sh
