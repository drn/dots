autoload -U compaudit compinit

# delegate _git_rb completion to _git_rebase
_git_rb () { _git_rebase }

# delegate _git_cp completion to _git_cherry_pick
_git_cp () { _git_cherry_pick }

# git completion
source /usr/local/etc/bash_completion.d/git-completion.bash 2>/dev/null

# zsh completion style
zstyle ':completion:*' menu yes select
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
# case insensitive, hyphen-insensitive, partial-word and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
