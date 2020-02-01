let g:ctrlp_show_hidden = 1
let g:ctrlp_map = '<leader>t'
let g:ctrlp_cmd = 'CtrlP'

noremap <silent> <leader>t :CtrlP<cr>
noremap <silent> <leader>T :CtrlPClearCache<bar>CtrlP<cr>
noremap <silent> <leader>b :CtrlPBuffer<cr>
noremap <silent> ;t :let g:ctrlp_working_path_mode = 'ra'<cr>
noremap <silent> ;T :let g:ctrlp_working_path_mode = 'ca'<cr>
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.(git|hg|svn|bundle)|coverage|tmp|vendor|node_modules)$',
  \ 'file': '\v\.(swp|zip|DS_Store|png|jpg|jpeg|svg|gif|eot|ttf|woff|rubocop-.*)$'
  \ }
let g:ctrlp_max_height = 20
let g:ctrlp_max_files = 0
" add ctrlp-funky as an extension
let g:ctrlp_extensions = ['funky']
" allow ctrlp to close dirvish buffer
let g:ctrlp_reuse_window = 'dirvish'
