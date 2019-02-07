" Override vim-test vimux runner strategy
function! test#strategy#vimux(cmd) abort
  " always redetermine vimux runner index
  if exists('g:VimuxRunnerIndex')
    unlet g:VimuxRunnerIndex
  endif
  " clear terminal history
  call VimuxClearRunnerHistory()
  let echo = 'echo -e ' . shellescape(a:cmd)
  " prepend shrink and clear commands
  call VimuxRunCommand(join(['shrink', 'clear', l:echo, a:cmd], '; '))
endfunction
