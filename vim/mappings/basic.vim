" Open base directory in netrw
nnoremap <silent> <leader>- :e `pwd`<cr>zz
" Clear search highlights
nnoremap <silent> ;k :noh<cr>
" Reindent current file and return to previous location
nnoremap <leader>I mzgg=G`z<CR>
" Save file as root
noremap <leader>W :w !sudo tee % > /dev/null<cr>
" Delete the next search match
nnoremap <silent> mn :execute "normal! hnd" . strlen(@/) . "l"<cr>
" Quick replace global
nnoremap <leader>C :%s//
" Quick replace after cursor
nnoremap <leader>c :.,$s//
" Break long string before 80
nnoremap <leader>b 77<Bar>i''<Esc>i<Return><Esc>kA\<Esc>j
" Delete from beggining of current line to end of last
nnoremap <silent> B ^d0i<BS>
" Redraw screen mapping
nnoremap <silent> <leader>D :redraw! <bar> echo 'Redrawing...'<cr>
" Visually select all
nnoremap <leader>a ggVG
" Echo path relative to working directory
nnoremap <leader>? :echo @%<cr>
