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

# install Homebrew managed dependencies
brew bundle $dotfiles/Brewfile

# install Rubygems
gem install bundler
bundle install --gemfile=$dotfiles/Gemfile
rm -f $dotfiles/Gemfile.lock
