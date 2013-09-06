#!/bin/bash

dev="$HOME/Development"
bin="/usr/local/bin"
="$HOME/.oh-my-zsh"

# install hub
gem install hub
hub hub standalone > $bin/hub && chmod +x $bin/hub
