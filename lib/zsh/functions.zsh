# Jump to root git root
function root() {
  git rev-parse 2>/dev/null && cd "$(git rev-parse --show-cdup)"
}

# Initialize Z
. /usr/local/etc/profile.d/z.sh
# Auto-rename tmux window
function _z_wrapper() {
  unset DISABLE_PROMPT
  _z $1
  if [[ "$TERM" = "screen"* ]] && [ -n "$TMUX" ]; then
    if [ -n "$1" ]; then
      if [[ $PWD == *"/Development/thanx/"* ]]; then
        if [ "$(tmux display-message -p '#{window_panes}')" = "1" ]; then
          tmux rename-window $(echo $PWD | sed 's/.*\/thanx\///')
        fi
      fi
    fi
  fi
}
alias ${_Z_CMD:-z}='_z_wrapper 2>&1'

function success?() {
  if [ $? = 0 ]; then
    echo -e "\033[0;32mSuccessful...\033[0m"
    $@
  else
    echo -e "\033[0;31mUnsuccessful...\033[0m"
  fi
}
