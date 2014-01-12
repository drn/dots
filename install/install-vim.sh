#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
vimsource="$dotfiles/vim"
vim="$HOME/.vim"
updateonly=false;
[ "$1" == "--update-only" ] && updateonly=true

# include install functions
source "$dotfiles/install/install.cfg"

# if not updateonly, destroy old non-bundle ~/.vim hierarchy
if ! $updateonly; then
  rm -rf $vim/ftplugin $vim/plugin $vim/autoload
fi

# ensure non-bundle ~/.vim hierarchy
mkdir -p $vim/autoload $vim/bundle $vim/ftplugin $vim/plugin/settings

# recursively link all vim configuration files
rlink $vimsource $vim

# install pathogen
if ! $updateonly; then
  echo "Installing Pathogen"
  curl -Sso $vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
fi

# install bundles
cd $vim/bundle

# list of vim plugins to install
plugins=(
  kien/ctrlp.vim
  JazzCore/ctrlp-cmatcher
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
  derekwyatt/vim-fswitch
  terryma/vim-multiple-cursors
  junegunn/vim-easy-align
  darrenli/vim-dispatch
  jgdavey/vim-turbux
  milkypostman/vim-togglelist
  rking/ag.vim
  mhinz/vim-startify
  puppetlabs/puppet-syntax-vim
  Valloric/YouCompleteMe
  nanotech/jellybeans.vim
  jeffkreeftmeijer/vim-numbertoggle
  vim-ruby/vim-ruby
  plasticboy/vim-markdown
  groenewege/vim-less
  tpope/vim-endwise
  tpope/vim-commentary
  Raimondi/delimitMate
  scrooloose/nerdtree
  tpope/vim-surround
  nathanaelkane/vim-indent-guides
  SirVer/ultisnips
  eiginn/netrw
  skammer/vim-css-color
  othree/html5.vim
  osyo-manga/vim-over
  elzr/vim-json
  tpope/vim-unimpaired
  tpope/vim-vinegar
  tpope/vim-eunuch
  StanAngeloff/php.vim
  sjl/gundo.vim
)

# prune existing directories not in plugin whitelist
existing=$vim/bundle/*
for file in $existing; do
  base_file="$(echo "$file" | sed 's/.*\///')"

  # determine if file in ~/.vim/bundle is whitelisted
  should_delete=true
  for plugin in "${plugins[@]}"; do
    base_plugin="$(echo "$plugin" | sed 's/.*\///' | sed 's/[ ].*//')"
    if [ "$base_plugin" == "$base_file" ]; then
      should_delete=false
    fi
  done

  # remove file if not whitelisted
  if $should_delete ; then
    echo "Removing $base_file from ~/.vim/bundle"
    rm -rf $file
  fi
done

# ensure all plugins in plugin list are up to date
for plugin in "${plugins[@]}"; do
  gitsync $plugin
done

# if not --update-only
if ! $updateonly; then

  # install YouCompleteMe binaries
  cd YouCompleteMe
  echo "Compiling YouCompleteMe binaries... This may take a while."
  ./install.sh --clang-completer >/dev/null 2>/dev/null
  success=$?
  if [[ $success -eq 0 ]]; then
    echo "YouCompleteMe binaries successfully compiled."
    sudo rm -f $dotfiles/install.log
  else
    echo "YouCompleteMe binaries failed to compile."
  fi
  cd $vim/bundle

  # install ctrlp-matcher extensions
  cd ctrlp-cmatcher
  echo "Compiling ctrlp-matcher binaries..."
  ./install_linux.sh >/dev/null 2>/dev/null
  success=$?
  if [[ $success -eq 0 ]]; then
    echo "ctrlp-matcher binaries successfully compiled."
    sudo rm -f $dotfiles/install.log
  else
    echo "ctrlp-matcher binaries failed to compile."
  fi
  cd $vim/bundle
fi
