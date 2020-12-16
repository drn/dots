# System Aliases
alias history='fc -l 1'
alias l='ls'
alias ls='nerd-ls -i'
alias la='nerd-ls -ai'
alias ll='nerd-ls -ail'
alias lt='nerd-ls -iT'
alias llt='nerd-ls -ilT'
alias sls='/bin/ls -G'
alias o.='open .'
alias o='open'
alias tree='tree -C'

# Navigation Aliases
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -g .......='../../../../../..'
alias -g ........='../../../../../../..'
alias -g .........='../../../../../../../..'

# Jump Aliases
alias dev='tmux rename-window dev 2>/dev/null; cd ~/Development'
alias doc='cd ~/Documents'
alias docs='cd ~/Documents'
alias dot='tmux rename-window dots 2>/dev/null; cd $DOTS'
alias down='tmux rename-window downloads 2>/dev/null; cd ~/Downloads'
alias dsk='tmux rename-window desktop 2>/dev/null; cd ~/Desktop'

# Command Aliases
alias binstubs='bundle install --binstubs .bundle/bin'
alias cat='bat'
alias ff='fuzzy-find'
alias fff='fuzzy-find-file'
alias g='git'
alias ggo='git go'
alias gitx='open -a /Applications/GitX.app .'
alias h='history'
alias hc='heroku console'
alias jo='jira-open'
alias notify='terminal-notifier -message'
alias nuc='thanx nucleus'
alias nup='thanx nucleus update'
alias orig='find . -iname "*.orig" | xargs rm'
alias pad='notes scratch-pad'
alias plane='airplane'
alias shrink='. shrink'
alias starwars='caffeinate -d telnet towel.blinkenlights.nl'
alias t='thanx'
alias tf='terraform'
alias top='vtop'
alias unshrink='. unshrink'
alias up='update'
alias update='dots update'
alias v.='nvim .'
alias v='nvim'
alias ver='thanx version'
alias vi='vim'
alias vimdiff='mvim -d'
alias vimsync="dots install vim"
alias vup='thanx version update'
alias ycm='cd ~/.vim/plugged/YouCompleteMe; ./install.py'
alias thanx='thanx-cli'
alias lip='local-ip'
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias acorn="ssh \$ACORN_USERNAME@\$ACORN_HOST"
alias sickchill="acorn ./bin/sickchill"
alias pi="ssh pi@192.168.0.201"
alias 1pass=". 1pass"
alias heic='heic-to-jpg'

# tmux-start shortcuts
alias mxm='unshrink; tmux-start master'
alias mxv='unshrink; tmux-start vertical'
