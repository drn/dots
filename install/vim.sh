#!/bin/bash

dev="$HOME/Development"
dotfiles="$dev/dotfiles"
vimsource="$dotfiles/vim"
vim="$HOME/.vim"
vimfile="$dotfiles/Vimfile"
updateonly=false;
[ "$1" == "--update-only" ] && updateonly=true

# include install functions
source "$dotfiles/install/core.cfg"

# remove all quickly-built directories
rm -rf $vim/ftplugin $vim/plugin

# if not updateonly, destroy ~/.vim/bundles hierarchy
if ! $updateonly; then
  rm -rf $vim/bundle $vim/autoload
fi

# ensure non-bundle ~/.vim hierarchy
mkdir -p $vim/autoload $vim/bundle $vim/ftplugin $vim/plugin/settings

# recursively link all vim configuration files
echo -e "\033[0;32mLinking all vim configuration files...\033[0m"
rlink $vimsource $vim

# install pathogen
if ! $updateonly; then
  echo "Installing Pathogen"
  curl -Sso $vim/autoload/pathogen.vim https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim
fi

# install bundles
cd $vim/bundle

# list of vim plugins to install
plugins=(); i=0
while read plugin; do
  plugins[i]="$plugin"; ((i+=1))
done < $vimfile

# prune existing directories not in plugin whitelist
echo -e "\033[0;32mEnforcing vim bundle whitelist...\033[0m"
existing=$vim/bundle/*
for file in $existing; do
  (
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
  ) &
done
wait

# ensure all plugins in plugin list are up to date
echo -e "\033[0;32mEnsuring all vim bundles are up-to-date...\033[0m"
for plugin in "${plugins[@]}"; do
  gitsync $plugin
done

# if not --update-only
if ! $updateonly; then

  # install YouCompleteMe binaries
  cd YouCompleteMe
  echo "Compiling YouCompleteMe binaries... This may take a while."
  git submodule update --init --recursive --depth 1
  ./install.sh
  success=$?
  if [[ $success -eq 0 ]]; then
    echo "YouCompleteMe binaries successfully compiled."
  else
    echo "YouCompleteMe binaries failed to compile."
  fi
  cd $vim/bundle

  # install ctrlp-matcher extensions
  cd ctrlp-cmatcher
  echo "Compiling ctrlp-matcher binaries..."
  export CFLAGS=-Qunused-arguments
  export CPPFLAGS=-Qunused-arguments
  ./install.sh
  success=$?
  if [[ $success -eq 0 ]]; then
    echo "ctrlp-matcher binaries successfully compiled."
  else
    echo "ctrlp-matcher binaries failed to compile."
  fi
  cd $vim/bundle
fi
