# Jump Aliases
alias dsk="cd ~/Desktop"
alias aud="vim ~/Dropbox/To\ Audrey.txt"
alias db="cd ~/Dropbox"
alias thanxdb="cd ~/Documents/Thanx/Dropbox"
alias thanxios="cd ~/Development/work/ios"
alias thanxrails="cd ~/Development/work/thanx-web"
alias thanxwww="cd ~/Development/work/www"
alias thanxdroid="cd ~/Development/work/eclipse-workspace/Thanx"
alias dev="cd ~/Development"
alias lib="cd ~/Development/library"
alias work="cd ~/Development/work"
alias doc="cd ~/Documents"
alias down="cd ~/Downloads"
alias bin="cd ~/bin"
alias todo="vi ~/bin/todo"

# SSH Aliases
alias dlc="ssh darrenli@darrenlincheng.com"
alias remotehome="ssh sanguinerane@sanguinerane.zapto.org"
alias localhome="ssh sanguinerane@192.168.2.200"

# Command Aliases
alias vi="mvim"
alias zshconfig="mvim ~/.zshrc"
alias vimrc="mvim ~/.vimrc"
alias gitconfig="mvim ~/.gitconfig"
alias gitstats="~/bin/gitstats.sh"
alias adb="~/Development/library/android-sdk-macosx/platform-tools/adb"
alias vimdiff="mvim -d"
alias crepo="~/Development/opensource/crepo/crepo.py"
alias rtest='ruby -I"lib:test"'
alias orig="find . -iname \"*.orig\" | xargs rm"
alias swp="find . -iname \"*.swp\" | xargs rm"
alias vim="/Applications/MacVim.app/Contents/MacOS/Vim"
alias sqldev='mysql -u root thanx_development'
alias gitk="~/.rvm/bin/gitk 2>/dev/null"
alias aliases="vi ~/.oh-my-zsh/custom/aliases.zsh"
alias theme="vi ~/.oh-my-zsh/custom/darrenli.zsh-theme"
alias custom="cd ~/.oh-my-zsh/custom"
alias dots="cd ~/Development/dotfiles"
alias space="sudo du -kx / | sort -nr | less"
alias springup="spring testunit; spring status;"

# System Maintenance Commands
update() {
  echo 'Updating Brew...'
  brew update
  echo '\n\nUpdating RVM...'
  rvm get stable
}
