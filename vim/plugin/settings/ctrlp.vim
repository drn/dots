let g:ctrlp_show_hidden = 1
noremap <silent> <leader>t :CtrlP<cr>
noremap <silent> <D-1> :let g:ctrlp_working_path_mode = 'ra'<cr>
noremap <silent> <D-2> :let g:ctrlp_working_path_mode = 'ca'<cr>
noremap <silent> <D-r> :CtrlPClearCache<cr>
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]((\.(git|hg|svn))|(coverage))$',
  \ 'file': '\v\.(swp|zip|DS_Store|jira-url)$'
  \ }
let g:ctrlp_match_func = {'match' : 'matcher#cmatch' }
let g:ctrlp_max_height = 20
let g:ctrlp_max_files = 0
" configure identifier color (CtrlP matching)
highlight CtrlPMatch guifg=#E94785

