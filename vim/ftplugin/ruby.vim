" run syntax checking
map <leader>S :w !ruby -c<CR>

" insert pry debug statement via insert abbreviation
iabbr rpry binding.pry_remote '0.0.0.0'
iabbr pry binding.pry
