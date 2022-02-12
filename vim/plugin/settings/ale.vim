" Override symbols
let g:ale_sign_error = '☿'
let g:ale_sign_warning = '☿'

" Override statusline
let g:ale_statusline_format = ['%d error(s)', '%d warning(s)', '']

" Disable reek and rubocop for ruby
let g:ale_linters = {
\ 'eruby': [],
\ 'javascript': ['eslint'],
\ 'typescript': ['tslint'],
\ 'ruby': ['ruby', 'rubocop', 'sorbet'],
\ 'terraform': ['terraform', 'tflint'],
\ 'solidity': []
\}

let g:ale_fixers = {
\ 'javascript': ['prettier'],
\ 'javascriptreact': ['prettier'],
\ 'typescript': ['prettier'],
\ 'solidity': ['prettier'],
\ 'css': ['prettier'],
\}

let g:ale_fix_on_save = 1

" Disable ale in CtrlP buffers
let g:ale_pattern_options = {
\ 'ControlP': {'ale_enabled': 0},
\}

" Disable ale by default in scratch-pad
au BufEnter scratch-pad :ALEDisable

" Toggle ale
map <leader>L :ALEToggle<cr>
