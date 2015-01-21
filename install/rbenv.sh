#!/bin/bash

# ensure rbenv has initialized before
rbenv init 2>/dev/null

# ensure rbenv plugin directory
mkdir -p $HOME/.rbenv/plugins

# install the following plugins
cd $plugins
# gitsync ...
