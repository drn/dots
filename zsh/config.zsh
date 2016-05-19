# Enable highlighters
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Override highlighter colors
typeset -gA ZSH_HIGHLIGHT_STYLES
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

# Set default shell editor
export EDITOR='nvim'

# Colorize man pages
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

# Set the default PostgreSQL host
export PGHOST=localhost

# Disable need to escape ^ characters
setopt NO_NOMATCH

# Set history size to 5k
HISTSIZE=10000

# Initialize Z
. /usr/local/etc/profile.d/z.sh
# Auto-rename tmux window
function _z_wrapper() {
  _z $1
  if [ "$TERM" = "screen" ] && [ -n "$TMUX" ]; then
    if [ -n "$1" ]; then
      if [[ $PWD == *"/thanx-"* ]]; then
        if [ "$(tmux display-message -p '#{window_panes}')" = "1" ]; then
          tmux rename-window $(echo $PWD | sed 's/.*\/thanx-//')
        fi
      fi
    fi
  fi
}
alias ${_Z_CMD:-z}='_z_wrapper 2>&1'

# Autoload tmux
if [ "$TMUX" = "" ]; then smux master; fi

# Autoload fzf
source ~/.fzf.zsh
