#!/bin/bash
source "$DOTS/install/core.cfg"

# ~ files
for location in $DOTS/lib/home/*; do
  file="${location##*/}"
  link "$location" "$HOME/.$file"
done
