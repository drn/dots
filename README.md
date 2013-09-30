Dotfiles
========

My development environment bootstrap script

### Installation

Single line installation:

    curl --silent https://raw.github.com/darrenli/dotfiles/master/install/install.sh | sh

### VIM

Vim configuration files (`.vimrc`, `.gvimrc`) files are installed.
Pathogen and the following bundles are installed to ~/.vim.

  * [ctrlp.vim](https://github.com/kien/ctrlp.vim/) - fast fuzzy file navigation
  * [vim-airline](https://github.com/bling/vim-airline/) - custom statusline
  * [vim-easymotion](https://github.com/Lokaltog/vim-easymotion) - extended vim motions
  * [vim-fugitive](https://github.com/tpope/vim-fugitive) - git wrapper
  * [vim-gitgutter](https://github.com/airblade/vim-gitgutter) - git gutter
  * [vim-rails](https://github.com/tpope/vim-rails) - vim rails support
  * [vim-ruby](https://github.com/vim-ruby/vim-ruby) - vim ruby support
  * [vim-bundler](https://github.com/tpope/vim-bundler) - vim bundler support
  * [syntastic](https://github.com/scrooloose/syntastic) - syntax checking
  * [vim-yardoc](https://github.com/noprompt/vim-yardoc) - YARD syntax highlighting
  * [cocoa.vim](https://github.commsanders/cocoa.vim) - vim cocoa support
  * [rainbow_parentheses.vim](https://github.com/kien/rainbow_parentheses.vim) - better parentheses syntax highlighting
  * [vim-signature](https://github.comkshenoy/vim-signature) - extended vim marks support
  * [vim-fswitch](https://github.com/derekwyatt/vim-fswitch) - easy companion file switching
  * [nerdcommenter](https://github.com/scrooloose/nerdcommenter) - commenting support
  * [vim-multiple-cursors](https://github.com/terryma/vim-multiple-cursors) - multiple cursor selections
  * [vim-easy-align](https://github.com/junegunn/vim-easy-align) - vim alignment support
  * [vim-turbux](https://github.com/jgdavey/vim-turbux) - vim ruby testing via tmux
  * [vim-dispatch](https://github.com/tpope/vim-dispatch) - asynchronous build and test dispatcher
  * [vim-togglelist](https://github.com/milkypostman/vim-togglelist) - easy toggling of quickfix menu
  * [ag.vim](https://github.com/rking/ag) - the silver searching vim integration
  * [vim-startify](https://github.com/mhinz/vim-startify) - fancy vim start screen
  * [puppet-syntax-vim](https://github.com/puppetlabs/puppet-syntax-vim) - puppet syntax highlighting for vim
  * [YouCompleteMe](https://github.comValloric/YouCompleteMe) - code-completion engine
  * [vim-numbertoggle](https://github.com/jeffkreeftmeijer/vim-numbertoggle) - easily toggle between relative and absolute line numbers
  * [jellybeans.vim](https://github.com/nanotech/jellybeans.vim) - my favorite color scheme with some modifications
  * [vim-markdown](https://github.com/plasticboy/vim-markdown) - markdown syntax
  * [vim-less](https://github.com/groenewege/vim-less) - less syntax

### Terminal

ZSH is set as the default shell. The following zsh config management
framework, oh-my-zsh plugins, tmux, and various terminal utilities are also
installed.

  * [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) - zsh configuration management framework
  * [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - additional shell syntax highlighting
  * [tmux](http://tmux.sourceforge.net/) - terminal multiplexer
  * [z](https://github.com/rupa/z) - weighted directory navigation

### Fonts

  * Menlo for Powerline

### Git

Default git configuration files (`.gitconfig`, `.gitignore`) are installed as
well as [Github's hub](https://github.com/github/hub) git wrapper.

## License

The MIT license.

Copyright (c) 2013 Darren Cheng (http://sanguinerane.com/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
