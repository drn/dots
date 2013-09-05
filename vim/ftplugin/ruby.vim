" Syntax Checking
map <leader>q :w !ruby -c<CR>
"autocmd BufWritePost * :w !ruby -c
" Helpers
nnoremap <silent> <leader><leader>l :call AppendRailsLogger()<cr>
nnoremap <silent> <leader><leader>d :call AppendPryDebugger()<cr>

if !exists("*AppendPryDebugger")
  function AppendPryDebugger()
    execute "normal a \<BS>binding.pry_remote '0.0.0.0'"
    startinsert!
  endfunction
endif

if !exists("*AppendRailsLogger")
  function AppendRailsLogger()
    execute "normal a \<BS>Rails.logger.info "
    startinsert!
  endfunction
endif




"" Hightlight all ## comments
highlight DoubleHash ctermbg=LightRed guibg=LightRed ctermfg=DarkMagenta guifg=DarkMagenta
3match DoubleHash /##.*$/

" Hightlight all ### comments
highlight TripleHash ctermbg=DarkMagenta guibg=DarkMagenta ctermfg=white guifg=white
2match TripleHash /###.*$/

