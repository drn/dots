# Set up console prompt
#   [darrencheng:dotfiles] (master:✗) ➜
#   [darrencheng:dotfiles] (master) ➜
#   [darrencheng:~] ➜
PROMPT='%{$fg_bold[red]%}%c%{$reset_color%}%{$reset_color%}$(git_prompt_info) %{$fg_bold[blue]%}➜%{$reset_color%}  '

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[blue]%}(⭠ %{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$reset_color%}:%{$fg[yellow]%}✗%{$fg[blue]%})"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
