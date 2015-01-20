augroup AutoSyntastic
  autocmd!
  autocmd BufWritePost * call s:syntastic()
augroup END

function! s:syntastic()
  if exists(':SyntasticCheck')
    SyntasticCheck
  endif
  call lightline#update()
endfunction
