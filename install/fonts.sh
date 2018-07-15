#!/bin/bash

# install fonts
for location in $DOTS/fonts/*; do
  file="${location##*/}"
  echo "Copying $location to $font/$file"
  cp -f "$location" "$HOME/Library/Fonts/$file"
done
