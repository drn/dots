#!/usr/bin/env zsh

autoload -U add-zsh-hook
setopt PROMPT_SUBST

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

prompt_directory_info() {
  if [[ $PWD == '/' ]]; then
    echo 'root'
  elif [[ ${#${PWD//[^\/]}} == 1 ]]; then
    echo 'rootchild'
  elif [[ $PWD == $HOME ]]; then
    echo 'home'
  elif [[ ${#${${PWD//$HOME}//[^\/]}} == 1 ]]; then
    echo 'homechild'
  else
    echo 'other'
  fi
}

prompt_directory_name() {
  if [[ ${PWD##*/} == .* ]] || [[ $PWD == $DOTS ]]; then
    surround="%{$fg_bold[cyan]%}\u00b7%{$reset_color%}"
    echo "$surround%{$fg_bold[red]%}${${PWD##*/}##.}%{$reset_color%}$surround"
  else
    local parent=$(basename $(dirname $PWD))
    local suffix="%{$fg_bold[red]%}$(basename $PWD)%{$reset_color%}"
    if [[ ${#parent} -gt 5 ]] || [[ ${#parent} -lt 2 ]]; then
      echo $suffix
    else
      echo "%{$fg_bold[red]%}$parent%{$fg[grey]%}/$suffix"
    fi
  fi
}

# Format directory listing
prompt_directory() {
  case "$(prompt_directory_info)" in
    root)
      echo "%{$fg_bold[white]%}/"
      ;;
    home)
      echo "%{$fg_bold[white]%}~"
      ;;
    rootchild)
      echo "%{$fg_bold[magenta]%}/ $(prompt_directory_name)"
      ;;
    homechild)
      echo "%{$fg_bold[magenta]%}~ $(prompt_directory_name)"
      ;;
    *)
      prompt_directory_name
      ;;
  esac
}

### Git Helpers

# return true (0) if current git repo is dirty, false (1) otherwise
prompt_git_dirty() {
  git_status=$(command git status -s 2> /dev/null | tail -n1)
  if [[ -n $git_status ]]; then return 0; else return 1; fi
}

# prompt if current directory is a git repo
prompt_git_info() {
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  local git_color="blue"
  if prompt_git_dirty; then git_color="yellow"; fi
  local prefix=" %{$fg_bold[$git_color]%}\ue0a0 %{$fg_no_bold[red]%}"
  local suffix="%{$reset_color%}"
  echo "$prefix${ref#refs/heads/}$suffix"
}

### ZSH Hooks

# precmd is called just before the prompt is printed
terminal_prompt_precmd() {
  # display elapsed command time if over CMD_MAX_EXEC_TIME
  local stop=$(date +%s)
  local start=${cmd_timestamp:-$stop}
  integer elapsed=$stop-$start
  (($elapsed > ${CMD_MAX_EXEC_TIME:=5})) && prompt_human_time $elapsed
  unset cmd_timestamp
  # rename tmux window depending on current directory
  if [[ "$TERM" = "screen"* ]] && [ -n "$TMUX" ]; then
    if [[ $PWD == *"/Development/thanx/"* ]]; then
      if [ "$(tmux display-message -p '#{window_panes}')" = "1" ]; then
        tmux rename-window $(echo $PWD | sed 's/.*\/thanx\///')
      fi
    fi
  fi
}

# preexec is called just before any command is executed
terminal_prompt_preexec() {
  cmd_timestamp=$(date +%s)
}

### Main Prompt Logic

# terminal prompt
terminal_prompt() {
  # success / failure indicator color
  if [ $? -eq 0 ]; then
    indicator_color="blue"
  else
    indicator_color="red"
  fi
  indicator="%{$fg_bold[$indicator_color]%}\u276F%{$reset_color%} "
  # shrunk prompt
  if [ -z "$DISABLE_PROMPT" ]; then
    echo "$(prompt_directory)$(prompt_git_info) $indicator"
  else
    echo $indicator
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
