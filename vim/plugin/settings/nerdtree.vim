" don't replace netrw
let g:NERDTreeHijackNetrw = 0
nmap <leader>1 :NERDTreeToggle<CR>
nmap <leader>! :NERDTreeFind<CR>
" close vim if nerdtree is the only window left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
" automatically close nerdtree on file open
let NERDTreeQuitOnOpen = 1
