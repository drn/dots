# Jump Aliases
alias dots='cd ~/.dots'
alias dsk='cd ~/Desktop'
alias db='cd ~/Dropbox'
alias tdb='cd ~/Documents/Thanx/Dropbox\ \(Thanx\)'
alias dev='cd ~/Development'
alias work='cd ~/Development/work'
alias doc='cd ~/Documents'
alias docs='cd ~/Documents'
alias down='cd ~/Downloads'
alias root="cd $(git root)"
alias logs="cd ~/.logs"

# SSH Aliases
alias dlc='ssh darrenli@darrenlincheng.com'
alias jenkins='ssh bitnami@jenkins.thanx.com'

# Command Aliases
alias rtest='ruby -I"lib:test"'
alias orig='find . -iname "*.orig" | xargs rm'
alias swp='find . -iname "*.swp" | xargs rm'
alias gitx='open -a ~/Applications/GitX.app .'
alias light='open -a /Applications/LightPaper.app'
alias update='. update'
alias up="update"
alias shrink='. shrink'
alias unshrink='. unshrink'
alias aud='vim ~/Dropbox/To\ Audrey.txt'
alias h='history'
alias top='htop'
alias j='jira'
alias o='open'
alias o.='open .'
alias binstubs='bundle install --binstubs .bundle/bin'
alias secure='v ~/.secure'
alias todo='notes todo'
alias pad='notes scratch-pad'
alias note='notes note'
alias v.='vim .'
alias v='vim'
alias vn='vim -u NONE'
alias vnone='vim -u NONE'
alias vimdiff='mvim -d'
alias vi='vim'
alias ls='ls -G'
alias l='ls -lah'
alias la='ls -lAh'
alias lr='ls -lR'
alias g='git'
alias vimsync="bash $DOTS/install/vim.sh"
alias ff="fuzzy-find"
alias fff="fuzzy-find-file"
alias nuc="nucleus"

# Tmuxinator Aliases
alias mxm='mux master'
alias mxv='mux vertical'
alias mxd='mux dots'
