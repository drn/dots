" disable .ycm_extra_conf.py confirmation prompt
let g:ycm_confirm_extra_conf = 0
" disable diagnostics mapping
let g:ycm_key_detailed_diagnostics = ''
" st python interpreter path
let g:ycm_path_to_python_interpreter = '/usr/local/bin/python'

" make YCM compatible with UltiSnips (using supertab)
let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
