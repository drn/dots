let g:toggle_list_no_mappings = 1
function! ToggleQuickfix()
  call plug#load('vim-togglelist')
  call ToggleQuickfixList()
endfunction
nnoremap <script> <silent> <leader>/ :call ToggleQuickfix()<CR>
