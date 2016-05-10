# Jump Aliases
alias dots='tmux rename-window dots; cd ~/.dots'
alias dsk='tmux rename-window desktop; cd ~/Desktop'
alias dev='tmux rename-window dev; cd ~/Development'
alias work='cd ~/Development/work'
alias doc='cd ~/Documents'
alias docs='cd ~/Documents'
alias down='tmux rename-window downloads; cd ~/Downloads'
alias logs="cd ~/.logs"

# SSH Aliases
alias dlc='ssh darrenli@darrenlincheng.com'
alias jenkins='ssh bitnami@jenkins.thanx.com'

# Command Aliases
alias rtest='ruby -I"lib:test"'
alias orig='find . -iname "*.orig" | xargs rm'
alias swp='find . -iname "*.swp" | xargs rm'
alias gitx='open -a /Applications/GitX.app .'
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
alias todo='tmux rename-window todo; notes todo'
alias pad='notes scratch-pad'
alias note='notes note'
alias think='tmux rename-window thoughts; notes thoughts'
alias v.='nvim .'
alias v='nvim'
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
alias nuc="thanx nucleus"
alias ver="thanx version"
alias smux="tmux-start"
alias t='thanx'
alias plane='airplane'

# tmux-start shortcuts
alias mxm='tmux-start master'
alias mxv='tmux-start vertical'
