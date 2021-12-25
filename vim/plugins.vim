call plug#begin('~/.vim/plugged')

" Run plug commands in current split
let g:plug_window = ''

" " jellybeans colorscheme
" Plug 'nanotech/jellybeans.vim'
" " statusline
" Plug 'itchyny/lightline.vim'
" " ale indicator for statusline
" Plug 'maximbaz/lightline-ale'
" " rainbow parentheses
" Plug 'luochen1990/rainbow'
" " start screen
" Plug 'mhinz/vim-startify'
" " relative and non-relative numberline toggle
" Plug 'jeffkreeftmeijer/vim-numbertoggle'
" " indent guides
" Plug 'nathanaelkane/vim-indent-guides'
" " vim git wrapper
" Plug 'tpope/vim-fugitive'
" " auto-add ending structures
" Plug 'tpope/vim-endwise'
" " modifying surroundings (parentheses, brackets, quotes, etc)
" Plug 'tpope/vim-surround'
" " [ and ] mappings
" Plug 'tpope/vim-unimpaired'
" " unix helpers (:SudoWrite)
" Plug 'tpope/vim-eunuch'
" " enable repeating of plugin commands
" Plug 'tpope/vim-repeat'
" " ga mapping to reveal decimal, octal, hex
" Plug 'tpope/vim-characterize'
" " bundler support
" Plug 'tpope/vim-bundler'
" " formatting coercion
" Plug 'tpope/vim-abolish'
" " extend % motions
" Plug 'andymass/vim-matchup'
" " yarddoc syntax highlighting
" Plug 'noprompt/vim-yardoc'
" " display register contents
" Plug 'junegunn/vim-peekaboo'
" " improved search functionality
" Plug 'junegunn/vim-slash'
" " linting engine
" Plug 'dense-analysis/ale'
" " fuzzy file finder
" Plug 'ctrlpvim/ctrlp.vim'
" " fuzzy function finder
" Plug 'tacahiroy/ctrlp-funky'
" " test runner
" Plug 'janko-m/vim-test'
" " send input to tmux, used by vim-test runner
" Plug 'preservim/vimux'
" " wakatime tracking
" Plug 'wakatime/vim-wakatime'
" " highlight yanked region
" Plug 'machakann/vim-highlightedyank'
" " directory viewer, netrw replacement
" Plug 'justinmk/vim-dirvish'
" " open terminal (got) & finder (gof) mappings
" Plug 'justinmk/vim-gtfo'
" " switch between single and multi-line statements
" Plug 'AndrewRadev/splitjoin.vim'
" " improved vimdiff
" Plug 'whiteinge/diffconflicts'
" " git commit browser (:GV)
" Plug 'junegunn/gv.vim'
" " file type icons
" Plug 'ryanoasis/vim-devicons'
" " additional text object selections
" Plug 'wellle/targets.vim'
" " distraction-free writing
" Plug 'junegunn/goyo.vim'
" " async inline color display
" Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
" " auto-highlight other * matches
" Plug 'RRethy/vim-illuminate'
" " Highlight f, F, t, T movement matches
" Plug 'unblevable/quick-scope'
" " Extended f, F, t, T movements mappings
" Plug 'rhysd/clever-f.vim'
" " commit messages under cursor
" Plug 'rhysd/git-messenger.vim'
" " Auto-completion, LSP, & snippets
" Plug 'neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' }
" Plug 'neoclide/coc-snippets', {'do': 'yarn install --frozen-lockfile'}
" " tree explorer
" Plug 'scrooloose/nerdtree', { 'on': [ 'NERDTreeToggle', 'NERDTreeFind' ] }
" " display git status in nerdtree
" Plug 'Xuyuanp/nerdtree-git-plugin', { 'on': [ 'NERDTreeToggle', 'NERDTreeFind' ] }
" " undotree
" Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
" " working directory search
" Plug 'mileszs/ack.vim', { 'on': 'Ack' }
" " display gitgutter
" Plug 'airblade/vim-gitgutter', { 'on': 'GitGutterToggle' }
" " vim alignmentalign
" Plug 'junegunn/vim-easy-align', { 'on': 'EasyAlign' }
" " toggle quickfix
" Plug 'milkypostman/vim-togglelist', { 'on': 'ToggleQuickfix' }
" " focus on specific section
" Plug 'junegunn/limelight.vim', { 'on': 'Limelight' }
" " toggle comments
" Plug 'tpope/vim-commentary', { 'on': [
" \ '<Plug>Commentary',
" \ '<Plug>CommentaryLine'
" \ ] }
" " send text to tmux
" Plug 'jpalardy/vim-slime', { 'on': [
" \ '<Plug>SlimeRegionSend',
" \ '<Plug>SlimeParagraphSend',
" \ '<Plug>SlimeConfig'
" \ ] }
" " interactive scratchpad
" Plug 'metakirby5/codi.vim'
" " improved whitespace highlighting
" Plug 'ntpeters/vim-better-whitespace'
" " expanded wildmenu support
" Plug 'gelguy/wilder.nvim', { 'do': ':UpdateRemotePlugins' }

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
Plug 'TovarishFin/vim-solidity', { 'for': 'solidity' }

call plug#end()
