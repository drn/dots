" unmap conflicting ds mapping if in netrw
function! FixVimSurroundDirectoryBrowserConflict()
  if &filetype == 'netrw' || &filetype == 'dirvish'
    silent! nunmap ds
  else
    silent! nmap ds <Plug>Dsurround
  endif
endfunction
autocmd FileType,BufWinEnter * call FixVimSurroundDirectoryBrowserConflict()
