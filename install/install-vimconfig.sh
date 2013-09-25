#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
vim="$HOME/.vim"
load="$vim/autoload"
bundle="$vim/bundle"
ftplugin="$vim/ftplugin"

# include install functions
source "$dotfiles/install/install.cfg"

# recreate vim config hierarchy
sudo rm -rf $vim
mkdir -p $load $bundle $colors $ftplugin

# install vim ftplugin files
for location in $dotfiles/vim/ftplugin/*; do
  file="${location##*/}"
  link "$location" "$ftplugin/$file"
done

# install pathogen
echo "Installing Pathogen"
curl -Sso ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim

# install bundles
cd $bundle

# list of vim plugins to install
plugins=(
  kien/ctrlp.vim
  bling/vim-airline
  Lokaltog/vim-easymotion
  tpope/vim-fugitive
  airblade/vim-gitgutter
  tpope/vim-rails
  tpope/vim-bundler
  scrooloose/syntastic
  noprompt/vim-yardoc
  msanders/cocoa.vim
  kien/rainbow_parentheses.vim
  kshenoy/vim-signature
  derekwyatt/vim-fswitch
  skalnik/vim-vroom
  scrooloose/nerdcommenter
  terryma/vim-multiple-cursors
  junegunn/vim-easy-align
  tpope/vim-dispatch
  jgdavey/vim-turbux
  milkypostman/vim-togglelist
  rking/ag
  mhinz/vim-startify
  puppetlabs/puppet-syntax-vim
  Valloric/YouCompleteMe
  nanotech/jellybeans.vim
)

# clone all plugins in plugin list
for plugin in "${plugins[@]}"; do
  clone "$plugin"
done

# install YouCompleteMe binaries
cd YouCompleteMe
echo "Compiling YouCompleteMe binaries... This may take a while."
./install.sh >/dev/null 2>$dotfiles/install.log
success=$?
if [[ $success -eq 0 ]]; then
  echo "YouCompleteMe binaries successfully compiled."
  sudo rm -f $dotfiles/install.log
else
  echo "YouCompleteMe binaries failed to compile. Please see $dotfiles/install.log for additional info."
fi
cd $bundle
