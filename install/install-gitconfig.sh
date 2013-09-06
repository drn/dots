#!/bin/bash

dev="$HOME/Development"
bin="/usr/local/bin"

# install hub
gem install hub
hub hub standalone > $bin/hub && chmod +x $bin/hub
