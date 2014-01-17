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
alias jira-cli="cd ~/Development/personal/jira-cli"
alias casks="cd /usr/local/bin/Library/Taps/phinze-cask"
alias casksv="cd /usr/local/bin/Library/Taps/caskroom-versions"

# SSH Aliases
alias dlc="ssh darrenli@darrenlincheng.com"
alias remotehome="ssh SanguineRane@sanguinerane.zapto.org"
alias localhome="ssh SanguineRane@192.168.1.200"

# Command Aliases
# clear terminal buffer after vim exits
vim() { /usr/local/bin/mvim -v $1; clear }
alias vi="mvim"
alias v="vim"
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
alias sqldev='mysql -u root thanx_development'
alias aliases="vi ~/.oh-my-zsh/custom/aliases.zsh"
alias theme="vi ~/.oh-my-zsh/custom/darrenli.zsh-theme"
alias custom="cd ~/.oh-my-zsh/custom"
alias dots="cd ~/Development/dotfiles"
alias space="sudo du -kx / | sort -nr | less"
alias springup="rake db:test:prepare; spring testunit; spring status;"
alias sup="springup"
alias vimsync="bash $HOME/Development/dotfiles/install/install-vim.sh --update-only"
alias j="jira"
alias todo="vi ~/bin/todo"
alias gitx="open -a ~/Applications/GitX.app ."
alias light="open -a /Applications/LightPaper.app"

# System Maintenance Commands
update() {
  sudo -p "Enter your password: " echo "We're good to go!"
  echo ""
  # update Oh My Zsh
  /usr/bin/env ZSH=$ZSH /bin/sh $ZSH/tools/upgrade.sh
  echo "LAST_EPOCH=$(($(date +%s) / 60 / 60 / 24))" > ~/.zsh-update
  # update and upgrade Homebrew
  echo -e '\n\033[0;34mUpdating Brew and any outdated packages...\033[0m'
  brew update; brew upgrade
  # update VIM plugins
  echo "\n\033[0;34mUpdating vim plugins...\033[0m"
  vimsync
}

# Tmux Aliases
thanx() {
  tmux has-session -t thanxrails
  if [ $? != 0 ]; then
    tmux new-session -s thanxrails -n editor -d
    tmux send-keys -t thanxrails 'source ~/.zshrc; cd ~/Development/work/thanx-web; clear' C-m
    tmux split-window -v -t thanxrails
    tmux send-keys -t thanxrails 'source ~/.zshrc; clear' C-m
    tmux split-window -v -t thanxrails
    tmux send-keys -t thanxrails 'source ~/.zshrc; clear' C-m
    tmux select-layout -t thanxrails main-horizontal
    #tmux send-keys -t thanxrails:0.1 'cd /var/www/htdocs/' C-m
    tmux new-window -n console -t thanxrails
    #tmux send-keys -t thanxrails:1 'cd /var/www/htdocs/' C-m
    tmux select-window -t thanxrails:0
  fi
  tmux attach -t thanxrails
}

