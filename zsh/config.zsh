# Enable highlighters
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Override highlighter colors
ZSH_HIGHLIGHT_STYLES[default]=none
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=green
ZSH_HIGHLIGHT_STYLES[alias]=fg=magenta,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=magenta,bold
ZSH_HIGHLIGHT_STYLES[function]=fg=magenta,bold
ZSH_HIGHLIGHT_STYLES[command]=fg=magenta,bold
ZSH_HIGHLIGHT_STYLES[precommand]=none
ZSH_HIGHLIGHT_STYLES[commandseparator]=none
ZSH_HIGHLIGHT_STYLES[hashed-command]=none
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[globbing]=none
ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=none
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=none
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=white,bold
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=white,bold
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=cyan
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=cyan
ZSH_HIGHLIGHT_STYLES[assign]=none

# Colorize man pages
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

# Disable need to escape ^ characters
setopt NO_NOMATCH

# Set history size to 5k
HISTSIZE=5000

# Initialize Z
. /usr/local/bin/z.sh

# Disable tab completion
compdef -d rake

# source travis gem
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh

# Autoload tmux
# if [ "$TMUX" = "" ]; then tmux; fi

# capture the working directory of tmux
precmd() {
  if [[ -n "$TMUX" ]]; then
    tmux setenv "$(tmux display -p 'TMUX_PWD_#D')" "$PWD"
  fi
}
