" custom mappings
nmap <leader>r :TestFile<cr>
nmap <leader>R :TestNearest<cr>
let test#strategy = 'vimux'

function! test#strategy#vimux(cmd) abort
  if exists('g:VimuxRunnerIndex')
    unlet g:VimuxRunnerIndex
  endif
  call VimuxClearRunnerHistory()
  let echo = 'echo -e ' . shellescape(a:cmd)
  call VimuxRunCommand(join(['shrink', 'clear', l:echo, a:cmd], '; '))
endfunction

function! test#javascript#jest#executable() abort
  return 'yarn test'
endfunction
