#!/bin/bash
source "$DOTS/install/core.cfg"

# ~ files
for location in $DOTS/home/*; do
  file="${location##*/}"
  link "$location" "$HOME/.$file"
done
