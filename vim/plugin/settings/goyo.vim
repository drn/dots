noremap <silent> <leader>, :Goyo<cr>

let g:goyo_width = 130

function! s:goyo_leave()
  call ConfigureUI()
endfunction

autocmd! User GoyoLeave nested call <SID>goyo_leave()
