# Set up console prompt
#   dotfiles (⭠ master ☿) ➜
#   dotfiles (⭠ master) ➜
#   ~ ➜
#   ❯

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[blue]%}(⭠ %{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$reset_color%} %{$fg[yellow]%}☿%{$fg[blue]%})"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"

terminal_prompt() {
  if [ $? -eq 0 ]; then
    # success
    if [ -z "$DISABLE_PROMPT" ]; then
      echo "%{$fg_bold[red]%}%c%{$reset_color%}%{$reset_color%}$(git_prompt_info) %{$fg_bold[blue]%}➜%{$reset_color%}  "
    else
      echo "%{$fg_bold[blue]%}❯%{$reset_color%} "
    fi
  else
    # failure
    if [ -z "$DISABLE_PROMPT" ]; then
      echo "%{$fg_bold[red]%}%c%{$reset_color%}%{$reset_color%}$(git_prompt_info) %{$fg_bold[red]%}➜%{$reset_color%}  "
    else
      echo "%{$fg_bold[red]%}❯%{$reset_color%} "
    fi
  fi
}

PROMPT='$(terminal_prompt)'
