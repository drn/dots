" Set ack.vim executable
if executable('rg')
  let g:ackprg = 'rg --vimgrep --smart-case'
endif
" Mapping shortcut to search via the silver search
nnoremap <leader>F :Ack<Space>
" Jump to next item in search
nnoremap <silent> + :cn<CR>z.
" Jump to next item in search
nnoremap <silent> _ :cp<CR>z.
