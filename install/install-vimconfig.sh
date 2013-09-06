#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
vim="$HOME/.vim"
bundle="$HOME/.vim/bundle"

# include install functions
source "$dotfiles/install/install.cfg"

# recreate vim config hierarchy
rm -rf $vim
mkdir -p "$vim/autoload" "$vim/bundle"

# install pathogen
echo "Installing Pathogen"
curl -Sso ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim

# install bundles
cd $bundle

# install ctrlp.vim
clone git://github.com/kien/ctrlp.vim.git

# install vim-airline
clone git://github.com/bling/vim-airline.git

# install vim-easymotion
clone git://github.com/Lokaltog/vim-easymotion.git

# install vim-fugitive
clone git://github.com/tpope/vim-fugitive.git

# install vim-gitgutter
clone git://github.com/airblade/vim-gitgutter.git

# install vim-rails
clone git://github.com/tpope/vim-rails.git
clone git://github.com/tpope/vim-bundler.git

# install syntastic
clone git://github.com/scrooloose/syntastic.git

# install vim-yardoc
clone git://github.com/noprompt/vim-yardoc.git

# install cocoa.vim
clone git://github.com/msanders/cocoa.vim.git

# install rainbow_parentheses
clone git://github.com/kien/rainbow_parentheses.vim.git

# install vim-signature
clone git://github.com/kshenoy/vim-signature.git

# install vim-fswitch
clone git://github.com/derekwyatt/vim-fswitch.git

# install YouCompleteMe
clone git://github.com/Valloric/YouCompleteMe.git
cd YouCompleteMe
echo "Compiling YouCompleteMe binaries... This may take a while."
./install.sh >/dev/null 2>$dotfiles/install.log
success=$?
if [[ $success -eq 0 ]]; then
  echo "YouCompleteMe binaries successfully compiled."
  rm -f $dotfiles/install.log
else
  echo "YouCompleteMe binaries failed to compile. Please see $dotfiles/install.log for additional info."
fi
cd $bundle

colors="$vim/colors"
ftplugin="$vim/ftplugin"
mkdir -p $colors $ftplugin

# install vim colors files
for location in $dotfiles/vim/colors/*; do
  file="${location##*/}"
  link "$location" "$colors/$file"
done

# install vim ftplugin files
for location in $dotfiles/vim/ftplugin/*; do
  file="${location##*/}"
  link "$location" "$ftplugin/$file"
done
