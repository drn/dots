#!/bin/bash -eux

echo 'Installing golang'
brew install go
# set local script env vars
export GOPATH=$HOME/go
export PATH=$HOME/go/bin:$PATH
# set job env vars
echo 'export GOPATH=$HOME/go' >> $BASH_ENV
echo 'export PATH=$HOME/go/bin:$PATH' >> $BASH_ENV
