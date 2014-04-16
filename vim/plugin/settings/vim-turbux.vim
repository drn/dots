" assign custom mappings
let g:no_turbux_mappings = 1
" custom mappings
nmap <leader>r <Plug>SendTestToTmux
nmap <leader>R <Plug>SendFocusedTestToTmux
" use custom turbux runner
let g:turbux_custom_runner = 'TurbuxCustomRunner'
function! TurbuxCustomRunner(command)
  call VimuxRunCommand("clear")
  call VimuxRunCommand(a:command)
  call VimuxClearRunnerHistory()
endfunction
" clear screen and shrink prompt before each test
let g:turbux_command_prefix='shrink;'
