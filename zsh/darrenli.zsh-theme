# Set up console prompt
#   dotfiles ⭠ master ❯
#   ~ ❯
#   ❯

# return true (0) if current git repo is dirty, false (1) otherwise
prompt_git_dirty() {
  git_status=$(command git status -s 2> /dev/null | tail -n1)
  if [[ -n $git_status ]]; then return 0; else return 1; fi
}

# prompt if current directory is a git repo
function prompt_git_info() {
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  local prefix=" %{$fg[blue]%}⭠ %{$fg[red]%}"
  if prompt_git_dirty; then
    local prefix=" %{$fg[magenta]%}⭠ %{$fg[red]%}"
  fi
  local suffix="%{$reset_color%}"
  echo "$prefix${ref#refs/heads/}$suffix"
}

# terminal prompt
terminal_prompt() {
  if [ $? -eq 0 ]; then
    # success
    indicator="%{$fg_bold[blue]%}❯%{$reset_color%} "
    if [ -z "$DISABLE_PROMPT" ]; then
      echo "%{$fg_bold[red]%}%c%{$reset_color%}$(prompt_git_info) $indicator"
    else
      echo $indicator
    fi
  else
    # failure
    indicator="%{$fg_bold[red]%}❯%{$reset_color%} "
    if [ -z "$DISABLE_PROMPT" ]; then
      echo "%{$fg_bold[red]%}%c%{$reset_color%}$(prompt_git_info) $indicator"
    else
      echo $indicator
    fi
  fi
}

PROMPT='$(terminal_prompt)'
