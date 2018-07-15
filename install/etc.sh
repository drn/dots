#!/bin/bash
source "$DOTS/install/core.cfg"

# /etc files
for location in $DOTS/etc/*; do
  file="${location##*/}"
  overwrite "$location" "/etc/$file"
done
