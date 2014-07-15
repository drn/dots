#!/bin/bash

# directory references
rbenv="$HOME/.rbenv"
plugins="$rbenv/plugins"
dev="$HOME/Development"
dotfiles="$dev/dotfiles"

# include install functions
source "$dotfiles/install/core.cfg"

# ensure rbenv has initialized before
rbenv init 2>/dev/null

# ensure rbenv plugin directory
mkdir -p ~/.rbenv/plugins

# install the following plugins
cd $plugins
# gitsync ...
