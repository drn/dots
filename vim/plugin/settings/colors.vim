""" Jellybeans.vim Colorscheme """

let g:jellybeans_use_lowcolor_black = 0
let g:jellybeans_background_color = "151535"
let g:jellybeans_background_color_256 = "none"
let g:jellybeans_overrides = {
\  'Todo': {
\    'guifg':    'DF4085',
\    'guibg':    '',
\    'ctermfg':  'Red',
\    'ctermbg':  '',
\    'attr':     'bold'
\  },
\}
colorscheme jellybeans
color jellybeans


""" Configure UI """

" sign column highlight should be clear
highlight clear SignColumn
" highlight and color the current line
set cursorline
highlight CursorLine guibg=#000070
" configure and color the cursor
set guicursor=n-v-c:blinkwait500-blinkoff500-blinkon500
highlight Cursor guibg=#C92765
" configure and color the color column
if exists('+colorcolumn')
  set colorcolumn=80
  hi ColorColumn guibg=#444444
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
endif

