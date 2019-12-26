call plug#begin('~/.vim/plugged')

" Allow YCM time to compile
let g:plug_timeout = 180
" Run plug commands in current split
let g:plug_window = ''

Plug 'nanotech/jellybeans.vim'
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
Plug 'luochen1990/rainbow'
Plug 'mhinz/vim-startify'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-characterize'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-abolish'
Plug 'gregsexton/gitv'
Plug 'andymass/vim-matchup'
Plug 'noprompt/vim-yardoc'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'junegunn/vim-peekaboo'
Plug 'junegunn/vim-slash'
Plug 'dense-analysis/ale'
" not lazyloaded to ensure ruby configuration is preloaded
Plug 'tpope/vim-rbenv'
" not lazyloaded to ensure proper load order
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tacahiroy/ctrlp-funky'
" not lazyloaded to preserve functionality
Plug 'janko-m/vim-test'
Plug 'benmills/vimux'
Plug 'wakatime/vim-wakatime'
Plug 'machakann/vim-highlightedyank'
Plug 'justinmk/vim-dirvish'
Plug 'justinmk/vim-gtfo'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'whiteinge/diffconflicts'
Plug 'junegunn/gv.vim'
Plug 'SirVer/ultisnips'
Plug 'ervandew/supertab'
Plug 'ryanoasis/vim-devicons'
Plug 'unblevable/quick-scope'
Plug 'rbong/vim-flog', { 'on': [ 'Flog', 'Flogsplit' ] }
Plug 'wellle/targets.vim'
" distraction-free writing
Plug 'junegunn/goyo.vim'
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
" auto-close parentheses
Plug 'cohama/lexima.vim'
" auto-highlight other * matches
Plug 'RRethy/vim-illuminate'

" Lazy-load plugins
Plug 'scrooloose/nerdtree', { 'on': [ 'NERDTreeToggle', 'NERDTreeFind' ] }
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
Plug 'mileszs/ack.vim', { 'on': 'Ack' }
Plug 'airblade/vim-gitgutter', { 'on': 'GitGutterToggle' }
Plug 'derekwyatt/vim-fswitch', { 'on': 'FSHere' }
Plug 'junegunn/vim-easy-align', { 'on': 'EasyAlign' }
Plug 'milkypostman/vim-togglelist', { 'on': [] }
Plug 'mattn/gist-vim', { 'on': 'Gist' }
Plug 'mattn/webapi-vim', { 'on': 'Gist' }
Plug 'junegunn/limelight.vim', { 'on': 'Limelight' }
Plug 'tpope/vim-commentary', { 'on': [
\ '<Plug>Commentary',
\ '<Plug>CommentaryLine'
\ ] }
Plug 'tpope/vim-speeddating', { 'on': [
\ '<Plug>SpeedDatingUp',
\ '<Plug>SpeedDatingDown'
\ ] }
Plug 'jpalardy/vim-slime', { 'on': [
\ '<Plug>SlimeRegionSend',
\ '<Plug>SlimeParagraphSend',
\ '<Plug>SlimeConfig'
\ ] }

" Language-specific plugins
Plug 'keith/rspec.vim', { 'for': 'ruby' }
Plug 'vim-ruby/vim-ruby', { 'for': ['ruby', 'eruby'] }
Plug 'neoclide/vim-jsx-improve', { 'for': ['javascript', 'javascript.jsx'] }
Plug 'othree/html5.vim', { 'for': ['html', 'eruby.html'] }
Plug 'zaiste/tmux.vim', { 'for': 'tmux' }
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'Keithbsmiley/swift.vim', { 'for': 'swift' }
Plug 'kchmck/vim-coffee-script', { 'for': 'coffee' }
Plug 'hashivim/vim-terraform', { 'for': 'terraform' }
Plug 'tpope/vim-rails', { 'for': [ 'ruby', 'eruby' ] }
Plug 'kana/vim-textobj-user', { 'for': [ 'ruby', 'eruby' ] }
Plug 'nelstrom/vim-textobj-rubyblock', { 'for': [ 'ruby', 'eruby' ] }
Plug 'vim-scripts/indenthtml.vim', { 'for': 'html' }
Plug 'vim-python/python-syntax', { 'for': 'python' }
Plug 'iamcco/markdown-preview.nvim', {
\ 'do': 'cd app & yarn install',
\ 'for': 'markdown'
\ }
Plug 'udalov/kotlin-vim', { 'for': 'kotlin' }
Plug 'fatih/vim-go', { 'for': 'go', 'do': ':GoUpdateBinaries' }
Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }

" Auto-completion
Plug 'neoclide/coc.nvim', { 'branch': 'release', 'tag': '*' }

" Non-neovim plugins
if $MYVIMRC !~ 'nvimrc'
  " ...
endif

call plug#end()
