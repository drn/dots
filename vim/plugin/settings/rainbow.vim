let g:rainbow_active = 0

" turn off rainbow parentheses in lua
function! PreventRainbowConflicts()
  if &filetype == 'lua'
    execute 'call rainbow#clear()'
  else
    execute 'call rainbow#hook()'
  endif
endfunction

if PluginExists('rainbow')
  autocmd FileType,BufWinEnter * call PreventRainbowConflicts()
endif
