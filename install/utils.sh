#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
opensource="$dev/opensource"
bin="/usr/local/bin"

# include install functions
source "$dotfiles/install/core.cfg"

# ensure z directory is available
touch ~/.z

# install pow
curl get.pow.cx | sh

# install homebrew if it is not yet installed
if ! hash brew 2>/dev/null; then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

# install bundle
brew bundle $dotfiles/Brewfile

# if rubygems is installed
if hash gem 2>/dev/null; then

  # ensure jira-cli is installed
  if [ -z "$(gem list | grep jira-cli)" ]; then
    echo "Installing jira-cli via rubygems"
    gem install jira-cli
  else
    echo "Updating jira-cli via rubygems"
    gem update jira-cli
  fi

  # ensure tmuxinator is installed
  if [ -z "$(gem list | grep tmuxinator)" ]; then
    echo "Installing tmuxinator via rubygems"
    gem install tmuxinator
  else
    echo "Updating tmuxinator via rubygems"
    gem update tmuxinator
  fi

fi

