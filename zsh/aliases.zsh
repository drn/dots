# System Aliases
alias history='fc -l 1'
alias l='ls'
alias la='nerd-ls -ai'
alias ll='nerd-ls -ail'
alias lls='nerd-ls -ailS'
alias llt='nerd-ls -ilT'
alias ls='nerd-ls -i'
alias lt='nerd-ls -iT'
alias o.='open .'
alias o='open'
alias sls='/bin/ls -G'

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
alias 1pass='. 1pass'
alias acorn-misc="mkdir -p ~/Downloads/misc; scp -r \$ACORN_USERNAME@\$ACORN_HOST:~/downloads/misc/* ~/Downloads/misc"
alias acorn="ssh \$ACORN_USERNAME@\$ACORN_HOST"
alias binstubs='bundle install; bundle binstubs --path .bundle/bin --all'
alias cat='bat'
alias cgo='git ci-go'
alias clean='dots cleanup'
alias ff='fuzzy-find'
alias fff='fuzzy-find-file'
alias g='git'
alias ggo='git go'
alias gh='git home'
alias gitx='open -a /Applications/GitX.app .'
alias h='history'
alias hcp='home-scp'
alias heic='heic-to-jpg'
alias home="ssh $HOME_USER@$HOME_WAN"
alias jo='jira-open'
alias lip='ip --local'
alias notify='terminal-notifier -message'
alias nuc='thanx nucleus'
alias orig='find . -iname "*.orig" | xargs rm'
alias pad='notes scratch-pad'
alias pi='ssh pi@192.168.0.201'
alias plane='airplane'
alias router='echo "http://$(ip --router)" | xargs open'
alias shrink='. shrink'
alias sickchill='acorn ./bin/sickchill'
alias starwars='caffeinate -d telnet towel.blinkenlights.nl'
alias stash-cert="scp ~/Downloads/cert_key.tar $HOME_USER@$HOME_WAN:~; home ./bin/stash-cert"
alias stash-stop='home ./bin/stash-stop'
alias stash='home ./bin/stash'
alias t='thanx'
alias tf='terraform'
alias thanx='thanx-cli'
alias top='vtop'
alias unshrink='. unshrink'
alias up='dots update'
alias v.='nvim .'
alias v='nvim'
alias ver='thanx version'
alias vi='vim'
alias vimdiff='nvim -d'
alias vimsync='dots install vim'
alias webp='webp-to-jpg'
alias wordle='ssh clidle.ddns.net -p 3000'
alias st="search-github thanx"

# tmux-start shortcuts
alias mxm='unshrink; tmux-start master'
alias mxv='unshrink; tmux-start vertical'
