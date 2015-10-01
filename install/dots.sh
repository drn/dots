#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# ~ files
for location in $HOME/.dots/home/*; do
  file="${location##*/}"
  link "$location" "$HOME/.$file"
done
