#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
opensource="$dev/opensource"
bin="/usr/local/bin"

# include install functions
source "$dotfiles/install/install.cfg"

# install hub
curl http://hub.github.com/standalone -sLo $bin/hub && chmod +x $bin/hub

# install z
sudo rm -rf $opensource/z
gitsync rupa/z $opensource/z
link $opensource/z/z.sh $bin/z.sh
link $opensource/z/z.1 /usr/local/share/man/man1/z.1
touch ~/.z

# if homebrew is installed
if hash brew 2>/dev/null; then

  # ensure tmux is installed
  if [ -z "$(brew list | grep tmux)" ]; then
    echo "Installing tmux via homebrew."
    brew install tmux
  fi

  # ensure the_silver_searcher (ag) is installed
  if [ -z "$(brew list | grep the_silver_searcher)" ]; then
    echo "Installing the_silver_searcher via homebrew."
    brew install the_silver_searcher
  fi

  # ensure tig is installed
  if [ -z "$(brew list | grep )" ]; then
    echo "Installing tig via homebrew."
    brew install tig
  fi

fi

