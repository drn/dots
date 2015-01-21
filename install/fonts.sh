#!/bin/bash

# install fonts
for location in $HOME/.dots/fonts/*; do
  file="${location##*/}"
  echo "Copying $location to $font/$file"
  cp -f "$location" "$HOME/Library/Fonts/$file"
done
