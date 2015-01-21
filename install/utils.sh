#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# ensure z directory is available
touch ~/.z

# install pow
curl get.pow.cx | sh

# install homebrew if it is not yet installed
if ! hash brew 2>/dev/null; then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

# install Homebrew managed dependencies
brew bundle $HOME/.dots/Brewfile
ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist

# install Rubygems
gem install bundler
bundle install --gemfile=$HOME/.dots/Gemfile
rm -f $HOME/.dots/Gemfile.lock
