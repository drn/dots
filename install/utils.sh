#!/bin/bash
source "$DOTS/install/core.cfg"

# ensure z directory is available
touch ~/.z

# configure neovim python dependencies
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# install python versions
pyenv install 2.7.11 -s
pyenv install 3.4.4 -s
# create virtualenvs
pyenv virtualenv 2.7.11 neovim2 || true
pyenv virtualenv 3.4.4 neovim3 || true
# neovim python 2
pyenv activate neovim2
pip install --upgrade pip
pip install --upgrade neovim
pyenv which python
# neovim python 3
pyenv activate neovim3
pip install --upgrade pip
pip install --upgrade neovim
pyenv which python
# install flake8 liner
pip install --upgrade flake8
ln -s `pyenv which flake8` ~/bin/flake8
# deactivate pyenv
pyenv deactivate

# install wakatime
pip2 install wakatime
