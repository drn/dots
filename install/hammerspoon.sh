#!/bin/bash

dotfiles="$HOME/Development/dotfiles"
hammerspoon="$dotfiles/hammerspoon/"
destination="$HOME/.hammerspoon"
source "$dotfiles/install/core.cfg"
link $hammerspoon $destination
