let g:ctrlp_show_hidden = 1
noremap <silent> <leader>t :CtrlP<cr>
noremap <silent> <leader>T :CtrlPClearCache<bar>CtrlP<cr>
noremap <silent> ;t :let g:ctrlp_working_path_mode = 'ra'<cr>
noremap <silent> ;T :let g:ctrlp_working_path_mode = 'ca'<cr>
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]((\.(git|hg|svn))|(coverage))$',
  \ 'file': '\v\.(swp|zip|DS_Store|jira-url)$'
  \ }
let g:ctrlp_match_func = {'match' : 'matcher#cmatch' }
let g:ctrlp_max_height = 20
let g:ctrlp_max_files = 0
" configure identifier color (CtrlP matching)
highlight CtrlPMatch guifg=#E94785 ctermfg=161
