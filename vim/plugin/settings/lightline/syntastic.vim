augroup AutoSyntastic
  autocmd!
  autocmd BufWritePost * call s:syntastic()
augroup END

function! s:syntastic()
  SyntasticCheck
  call lightline#update()
endfunction
