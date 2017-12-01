#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# ensure z directory is available
touch ~/.z

# install pow
curl get.pow.cx | sh

# install Homebrew managed dependencies
brew bundle --file=$HOME/.dots/Brewfile
brew services start mysql
brew services start postgresql

# install ruby and gems
rbenv install 2.4.1 -s
rbenv global 2.4.1
gem install bundler
bundle install --gemfile=$HOME/.dots/Gemfile
rm -f $HOME/.dots/Gemfile.lock

# install wakatime
pip install wakatime
