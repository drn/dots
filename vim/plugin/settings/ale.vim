" Override symbols
let g:ale_sign_error = '☿'
let g:ale_sign_warning = '☿'

" Override statusline
let g:ale_statusline_format = ['%d error(s)', '%d warning(s)', '']

" Disable reek and rubocop for ruby
let g:ale_linters = {
\ 'ruby': ['ruby'],
\ 'javascript': ['eslint'],
\ 'eruby': []
\}
