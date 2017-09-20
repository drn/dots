" use VIM settings, not vi settings
set nocompatible
" enable syntax highlighting
syntax on
set tabstop=2
set shiftwidth=2
" insert spaces instead of tabs
set expandtab
" show line numbers
set number
" disable error bell
set visualbell
" use auto-indentation
filetype plugin indent on
" set leader to ,
let mapleader = ","
" set minimum number of lines above and below cursor
set scrolloff=5
" turn on incremental searching
set incsearch
" speed up mappings
set ttimeout
set ttimeoutlen=50
" round >> shifting
set shiftround
" display tabs and trailing spaces visually
set list listchars=tab:ˍˍ,trail:ˍ
au FileType gitcommit set nolist
" toggle visible whitespace
nnoremap <silent> ;;w :set list!<cr>
" turn off .swp files
set noswapfile
set nobackup
set nowb
"" persistent file undo
if !isdirectory($HOME . "/.vim/backups")
  call mkdir($HOME . "/.vim/backups", "p")
endif
set undodir=$HOME/.vim/backups
set undofile
" smoother screen redraw
set ttyfast
" set background defaults
set background=dark
" highlight search matches
set hlsearch
" disable syntax highlighting past specified column for long lines
set synmaxcol=160
" hide all scrollbars in gui vim
set guioptions-=r
set guioptions-=l
set guioptions-=R
set guioptions-=L
" always show status line
set laststatus=2
" hide duplicate mode descriptions
set noshowmode
" set font
set guifont=Menlo\ for\ Powerline:h14
" disable Ex-only mapping
nnoremap Q <nop>
" disable man page lookup
nnoremap K <nop>
" enable mouse usage
set mouse=a
" backspace through lines
set backspace=indent,eol,start
" open all folds by default
set nofoldenable
" share clipboard with system
set clipboard=unnamed

" python2 interpreter path
let g:python_host_prog = $HOME . '/.pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = $HOME . '/.pyenv/versions/neovim3/bin/python'
