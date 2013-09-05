PROMPT='[%{$fg_bold[cyan]%}%n%{$reset_color%}:%{$fg_bold[red]%}%c%{$reset_color%}]$(git_prompt_info) %{$fg_bold[green]%}%h%{$reset_color%}) '

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[blue]%}(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$reset_color%}:%{$fg[yellow]%}✗%{$fg[blue]%})"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"

## Enable highlighters
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Override highlighter colors
ZSH_HIGHLIGHT_STYLES[default]=none
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=green
ZSH_HIGHLIGHT_STYLES[alias]=fg=magenta,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=magenta,bold
ZSH_HIGHLIGHT_STYLES[function]=gf=magenta,bold
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
