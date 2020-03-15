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

function colors() {
  echo -e "\033[0mNC (No Color)"
  echo -e "\033[1;37mWHITE\t\033[0;30mBLACK\033[0m"
  echo -e "\033[0;34mBLUE\t\033[1;34mLIGHT_BLUE\033[0m"
  echo -e "\033[0;32mGREEN\t\033[1;32mLIGHT_GREEN\033[0m"
  echo -e "\033[0;36mCYAN\t\033[1;36mLIGHT_CYAN\033[0m"
  echo -e "\033[0;31mRED\t\033[1;31mLIGHT_RED\033[0m"
  echo -e "\033[0;35mMAGENTA\t\033[1;35mLIGHT_MAGENTA\033[0m"
  echo -e "\033[0;33mYELLOW\t\033[1;33mLIGHT_YELLOW\033[0m"
  echo -e "\033[1;30mGRAY\t\033[0;37mLIGHT_GRAY\033[0m"
}
