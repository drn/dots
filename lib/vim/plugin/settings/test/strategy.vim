function! test#strategy#vimux(cmd) abort
  if exists('g:VimuxRunnerIndex')
    unlet g:VimuxRunnerIndex
  endif
  call VimuxClearRunnerHistory()
  let echo = 'echo -e ' . shellescape(a:cmd)
  call VimuxRunCommand(join(['shrink', 'clear', l:echo, a:cmd], '; '))
endfunction
