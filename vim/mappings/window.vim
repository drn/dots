" resize window mappings
nnoremap <silent> 'd :vertical resize +5<cr>
nnoremap <silent> 'a :vertical resize -5<cr>
nnoremap <silent> 's :resize -5<cr>
nnoremap <silent> 'w :resize +5<cr>

" open and switch to window right
nnoremap <silent> ''d :rightbelow wincmd v<cr>
" open and switch to window left
nnoremap <silent> ''a :leftabove wincmd v<cr>
" open and switch to window above
nnoremap <silent> ''w :leftabove wincmd s<cr>
" open window below
nnoremap <silent> ''s :rightbelow wincmd s<cr>
" resize windows evenly
nnoremap <silent> ''= :windcmd =<cr>

" move to window on the right
nnoremap <silent> ;d :wincmd l<cr>
" move to window on the left
nnoremap <silent> ;a :wincmd h<cr>
" move to window above
nnoremap <silent> ;w :wincmd k<cr>
" move to window below
nnoremap <silent> ;s :wincmd j<cr>

" move to window by number
let i = 1
while i <= 9
  execute 'nnoremap <silent> ;' . i . ' :' . i . 'wincmd w<CR>'
  let i = i + 1
endwhile

" rotate split windows
nnoremap <silent> ;r :wincmd r<cr>
