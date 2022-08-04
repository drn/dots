" Extensions
let g:coc_global_extensions = ['coc-snippets']

" Snippets

" Use <tab> for trigger completion, completion confirm, snippet expand, and jump
" See https://github.com/neoclide/coc-snippets#examples for source

inoremap <silent><expr> <TAB>
  \ coc#pum#visible() ? coc#_select_confirm() :
  \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
  \ CheckBackSpace() ? "\<TAB>" :
  \ coc#refresh()

function! CheckBackSpace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'
