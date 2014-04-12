" assign custom mappings
let g:no_turbux_mappings = 1
" custom mappings
nmap <leader>r <Plug>SendTestToTmux
nmap <leader>R <Plug>SendFocusedTestToTmux
" clear screen before each test
let g:turbux_command_prefix='clear;'
