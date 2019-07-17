noremap <silent> <leader>, :Goyo<cr>

function! s:goyo_leave()
  call ConfigureUI()
endfunction

autocmd! User GoyoLeave nested call <SID>goyo_leave()
