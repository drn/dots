autoload -U compaudit compinit

# completion delegation
_git_rb() { _git_rebase }
_git_cp() { _git_cherry_pick }
_git_f()  { _git_fetch }

# git completion
source /usr/local/etc/bash_completion.d/git-completion.bash 2>/dev/null

# zsh completion style
zstyle ':completion:*' menu yes select
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
# case insensitive, hyphen-insensitive, partial-word and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# adjust select-word-style
autoload -U select-word-style
select-word-style bash

# heroku completion
HEROKU_AC_ZSH_SETUP_PATH=$HOME/Library/Caches/heroku/autocomplete/zsh_setup && \
  test -f $HEROKU_AC_ZSH_SETUP_PATH && \
  source $HEROKU_AC_ZSH_SETUP_PATH
