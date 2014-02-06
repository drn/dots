" unmap conflicting ds mapping if in netrw
function! FixVimSurroundNetrwConflict()
  if &filetype == 'netrw'
    silent! nunmap ds
  else
    silent! nmap ds <Plug>Dsurround
  endif
endfunction
autocmd FileType,BufWinEnter * call FixVimSurroundNetrwConflict()
