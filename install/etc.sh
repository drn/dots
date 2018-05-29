#!/bin/bash
source "$HOME/.dots/install/core.cfg"

# /etc files
for location in $HOME/.dots/etc/*; do
  file="${location##*/}"
  overwrite "$location" "/etc/$file"
done
