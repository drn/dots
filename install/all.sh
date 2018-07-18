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

  # install placeholder ~/.zshenv
  rm -f $HOME/.zshenv
  echo "export PATH=/usr/local/bin:/usr/local/sbin:$PATH" >> $HOME/.zshenv

  echo "Your shell has changed. Relaunch terminal and rerun the installation."
  exit 0
fi

# directory setup
mkdir -p $HOME/Development

# TODO ensure dots are up-to-date
# go get -u github.com/drn/dots

echo "Install is complete. Relaunch terminal for settings to take effect."
