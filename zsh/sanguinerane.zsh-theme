# Set up console prompt
#   dotfiles ⭠ master ❯
#   ~ ❯
#   ❯

CMD_MAX_EXEC_TIME=5

### Format Helpers

# make input time human readable
#   thanks to https://github.com/sindresorhus/pure
prompt_human_time() {
  local tmp=$1
  local human_time=''
  local days=$(( tmp / 60 / 60 / 24 ))
  local hours=$(( tmp / 60 / 60 % 24 ))
  local minutes=$(( tmp / 60 % 60 ))
  local seconds=$(( tmp % 60 ))
  (( $days > 0 )) && human_time="$human_time${days}d "
  (( $hours > 0 )) && human_time="$human_time${hours}h "
  (( $minutes > 0 )) && human_time="$human_time${minutes}m "
  echo "$fg_bold[black]("\
       "$fg_no_bold[magenta]$human_time${seconds}s"\
       "$fg_bold[black])$reset_color"
}

### Git Helpers

# return true (0) if current git repo is dirty, false (1) otherwise
prompt_git_dirty() {
  git_status=$(command git status -s 2> /dev/null | tail -n1)
  if [[ -n $git_status ]]; then return 0; else return 1; fi
}

# prompt if current directory is a git repo
function prompt_git_info() {
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  local git_color="blue"
  if prompt_git_dirty; then git_color="yellow"; fi
  local prefix=" %{$fg_bold[$git_color]%}⭠ %{$reset_color%}%{$fg[red]%}"
  local suffix="%{$reset_color%}"
  echo "$prefix${ref#refs/heads/}$suffix"
}

### ZSH Hooks

# precmd is called just before the prompt is printed
terminal_prompt_precmd() {
  local stop=$(date +%s)
  local start=${cmd_timestamp:-$stop}
  integer elapsed=$stop-$start
  (($elapsed > ${CMD_MAX_EXEC_TIME:=5})) && prompt_human_time $elapsed
  unset cmd_timestamp
}

# preexec is called just before any command is executed
terminal_prompt_preexec() {
  cmd_timestamp=$(date +%s)
}

### Main Prompt Logic

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

# ensure precmd and preexec hooks are set up
setup_terminal_prompt() {
  # preexec is called just before any command is executed
  add-zsh-hook preexec terminal_prompt_preexec
  # precmd is called just before the prompt is printed
  add-zsh-hook precmd terminal_prompt_precmd
}
setup_terminal_prompt

PROMPT='$(terminal_prompt)'
