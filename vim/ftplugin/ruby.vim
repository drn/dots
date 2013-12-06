" run syntax checking
map <leader>q :w !ruby -c<CR>

" insert pry debug statement via insert abbreviation
iabbr rpry binding.pry_remote '0.0.0.0'
iabbr pry binding.pry
" insert pry debug statement via mapping
map <leader><leader>d obinding.pry_remote '0.0.0.0'<esc>
