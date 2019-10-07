" Override symbols
let g:ale_sign_error = '☿'
let g:ale_sign_warning = '☿'

" Override statusline
let g:ale_statusline_format = ['%d error(s)', '%d warning(s)', '']

" Disable reek and rubocop for ruby
let g:ale_linters = {
\ 'eruby': [],
\ 'javascript': ['eslint', 'flow', 'prettier'],
\ 'ruby': ['ruby', 'rubocop'],
\ 'terraform': ['terraform', 'tflint']
\}

" Disable ale in CtrlP buffers
let g:ale_pattern_options = {
\ 'ControlP': {'ale_enabled': 0},
\}

" Disable ale by default in scratch-pad
au BufEnter scratch-pad :ALEDisable

" Toggle ale
map <leader>L :ALEToggle<cr>
