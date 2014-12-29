## TL;DR

Quick Installation

    curl -s https://raw.github.com/drn/dotfiles/master/install/install.sh | sh

![vim/tmux/terminal](https://raw.githubusercontent.com/drn/dotfiles/master/screenshots/tmux-vim.png)

## Overview

These dotfiles are an ever-changing document of my development environment
configuration. I use these dotfiles and included installation scripts to
synchronize my setup across various machines.

The above 'quick installation' script runs through the setup, configuration,
and installation of the following sections:

  * dotfiles - basic `~/.*` config files
  * vim - vim
  * zsh - oh-my-zsh
  * git - custom functions, templates, hooks
  * utilities - terminal utilities
  * bin - custom scripts on the `$PATH`
  * fonts - development fonts
  * osx - os x system config

### Dots

All files in the [home](https://github.com/drn/dotfiles/tree/master/home)
directory are symlinked to `$HOME` with a `.` prefix.

### VIM

  * The [vimrc](https://github.com/drn/dotfiles/blob/master/home/vimrc)
    contains all non-plugin related mappings, configurations, and functions.
    This is auto-symlinked with the other `~/.*` files
  * The [Vimfile](https://github.com/drn/dotfiles/blob/master/Vimfile)
    is the canonical listing of the included 50+ vim plugins
  * [Plugin settings](https://github.com/drn/dotfiles/tree/master/vim/plugin/settings)
    are symlinked into the appropriate `~/.vim/*` location
  * Binaries for installed plugins are automatically compiled
  * A `vimsync` alias installed for easy bundle version management

### ZSH

The default shell is overridden and set to Homebrew installed ZSH.

  * [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) - zsh configuration management framework
  * [custom](https://github.com/drn/dotfiles/tree/master/zsh) shell prompt,
    aliases, plugins, completions are configured

### Git

  * Default config files (`.gitconfig`, `.gitignore`)
  * Custom [git extensions](https://github.com/drn/dotfiles/tree/master/git/functions)
    tailored to my workflow

### Utils

Terminal utilities and system tools are installed via the
[util script](https://github.com/drn/dotfiles/blob/master/install/utils.sh)

  * The [Brewfile](https://github.com/drn/dotfiles/blob/master/Brewfile)
    is the canonical listing of Homebrew installed utilities
  * Other utilities installed via other sources include:
    * [pow.cx](http://pow.cx) - zero-config rack server
    * [jira-cli](http://rubygems.org/gems/jira-cli) - JIRA workflow management
      CLI
    * [tmuxinator](https://github.com/tmuxinator/tmuxinator) - tmux session
      management

### Fonts

  * Menlo for Powerline

### OS X

[OS X Configuration](https://github.com/drn/dotfiles/blob/master/install/osx.sh)
including:

  * faster key press
  * disable sleep image
  * disable spotlight
  * etc.

## License

The MIT license.

Copyright (c) 2013 Darren Cheng (http://sanguinerane.com/)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
