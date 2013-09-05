#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
vim="$HOME/.vim"
bundle="$HOME/.vim/bundle"

if [[ -d "$dotfiles" ]]; then
  echo "Symlinking dotfiles from $dotfiles"
else
  echo "$dotfiles does not exist"
  exit 1
fi

# include install functions
source "$dotfiles/install/install.cfg"

# recreate vim config hierarchy
rm -rf $vim
mkdir -p "$vim/autoload" "$vim/bundle"

# install pathogen
curl -Sso ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim

# install bundles
cd $bundle

# install command-t
git clone git@github.com:wincent/Command-T.git .
cd command-t
rake make
cd $bundle

# install vim-airline
git clone git@github.com:bling/vim-airline.git .

# install vim-easymotion
git clone git@github.com:Lokaltog/vim-easymotion.git .

# install vim-fugitive
git clone git://github.com/tpope/vim-fugitive.git .

# install vim-gitgutter
git clone git://github.com/airblade/vim-gitgutter.git .

# install vim-rails
git clone git://github.com/tpope/vim-rails.git .
git clone git://github.com/tpope/vim-bundler.git .

# install syntastic
git clone git@github.com:scrooloose/syntastic.git .

# install vim-yardoc
git clone https://github.com/noprompt/vim-yardoc.git .

# install cocoa.vim
git clone git@github.com:msanders/cocoa.vim.git .

# install YouCompleteMe
git cline git@github.com:Valloric/YouCompleteMe.git .
cd YouCompleteMe
./install.sh
cd $bundle
