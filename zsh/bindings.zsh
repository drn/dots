# emacs key bindings
bindkey -e

# bind history substring keys
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# go to beginning of line
if [[ "${terminfo[khome]}" != "" ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line
fi
# go to end of line
if [[ "${terminfo[kend]}" != "" ]]; then
  bindkey "${terminfo[kend]}" end-of-line
fi
# delete from cursor to beginning of line
bindkey \^U backward-kill-line

# accepts and executes autosuggestion
bindkey '^[^M' autosuggest-execute # Alt + Enter

# atuin interactive search
bindkey '^r' _atuin_search_widget
