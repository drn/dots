#!/bin/bash

dev="$HOME/Development"
bin="/usr/local/bin"

# install hub
curl http://hub.github.com/standalone -sLo $bin/hub && chmod +x $bin/hub
