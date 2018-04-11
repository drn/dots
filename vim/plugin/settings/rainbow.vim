let g:rainbow_active = 0

" turn off rainbow parentheses in lua
function! PreventRainbowConflicts()
  if &filetype == 'lua'
    execute 'call rainbow_main#clear()'
  else
    execute 'call rainbow_main#load()'
  endif
endfunction

if PluginExists('rainbow')
  autocmd FileType,BufWinEnter * call PreventRainbowConflicts()
endif
