#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# ~ files
for location in $HOME/.dots/home/*; do
  file="${location##*/}"
  echo "$location to $HOME/.$file"
  link "$location" "$HOME/.$file"
done
