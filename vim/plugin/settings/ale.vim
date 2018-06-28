" Override symbols
let g:ale_sign_error = '☿'
let g:ale_sign_warning = '☿'

" Override statusline
let g:ale_statusline_format = ['%d error(s)', '%d warning(s)', '']

" Disable reek and rubocop for ruby
let g:ale_linters = {
\ 'ruby': ['ruby', 'rubocop'],
\ 'javascript': ['flow'],
\ 'eruby': []
\}

" Disable ale in CtrlP buffers
au BufEnter ControlP let b:ale_enabled = 0

" Toggle ale
map <leader>L :ALEToggle<cr>
