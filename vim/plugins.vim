call plug#begin('~/.vim/plugged')

" Allow YCM time to compile
let g:plug_timeout = 180
" Run plug commands in current split
let g:plug_window = ''

Plug 'nanotech/jellybeans.vim'
Plug 'itchyny/lightline.vim'
Plug 'eiginn/netrw'
Plug 'luochen1990/rainbow'
Plug 'mhinz/vim-startify'
Plug 'Lokaltog/vim-easymotion'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-characterize'
Plug 'vim-scripts/matchit.zip'
Plug 'maxbrunsfeld/vim-yankstack'
Plug 'jszakmeister/vim-togglecursor'
Plug 'noprompt/vim-yardoc'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'junegunn/vim-oblique'
" vim-oblique dependency
Plug 'junegunn/vim-pseudocl'
" not lazyloaded to ensure ruby configuration is preloaded
Plug 'tpope/vim-rbenv'
Plug 'vim-ruby/vim-ruby'
" not lazyloaded to ensure proper load order
Plug 'kien/ctrlp.vim'
Plug 'tacahiroy/ctrlp-funky'

" Lazy-load plugins
Plug 'scrooloose/nerdtree', { 'on': [ 'NERDTreeToggle', 'NERDTreeFind' ] }
Plug 'sjl/gundo.vim', { 'on': 'GundoToggle' }
Plug 'drn/zoomwin-vim', { 'on': 'ZoomWin' }
Plug 'rking/ag.vim', { 'on': 'Ag' }
Plug 'airblade/vim-gitgutter', { 'on': 'GitGutterToggle' }
Plug 'derekwyatt/vim-fswitch', { 'on': 'FSHere' }
Plug 'junegunn/vim-easy-align', { 'on': 'EasyAlign' }
Plug 'milkypostman/vim-togglelist', { 'on': [] }
Plug 'mattn/gist-vim', { 'on': 'Gist' }
Plug 'mattn/webapi-vim', { 'on': 'Gist' }
Plug 'junegunn/limelight.vim', { 'on': 'Limelight' }
Plug 'benmills/vimux', { 'on': [
\   '<Plug>SendTestToTmux',
\   '<Plug>SendFocusedTestToTmux'
\ ] }
Plug 'drn/vim-turbux', { 'on': [
\   '<Plug>SendTestToTmux',
\   '<Plug>SendFocusedTestToTmux'
\ ] }
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
Plug 'scrooloose/syntastic', { 'for': 'ruby' }
Plug 'tpope/vim-rails', { 'for': [ 'ruby', 'eruby' ] }
Plug 'kana/vim-textobj-user', { 'for': [ 'ruby', 'eruby' ] }
Plug 'nelstrom/vim-textobj-rubyblock', { 'for': [ 'ruby', 'eruby' ] }
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'Keithbsmiley/swift.vim', { 'for': 'swift' }
Plug 'zaiste/tmux.vim', { 'for': 'tmux' }
Plug 'othree/html5.vim', { 'for': 'html'}
Plug 'vim-scripts/indenthtml.vim', { 'for': 'html'}
Plug 'kchmck/vim-coffee-script', { 'for': 'coffee' }

" Non-neovim plugins
if $MYVIMRC !~ 'nvimrc'

  function! BuildYCM(info)
    " info is a dictionary with 3 fields
    " - name:   name of the plugin
    " - status: 'installed', 'updated', or 'unchanged'
    " - force:  set on PlugInstall! or PlugUpdate!
    if a:info.status == 'installed' || a:info.status == 'updated' || a:info.force
      !./install.sh
    endif
  endfunction
  Plug 'Valloric/YouCompleteMe', { 'do': function('BuildYCM') }

endif

call plug#end()
