" Manually run syntax checking in case syntastic borks
map <leader>S :w !ruby -c<CR>

""" Abbreviations
iabbr pry. binding.pry
iabbr logger. ActiveRecord::Base.logger = Logger.new(STDOUT)
iabbr arb. ActiveRecord::Base
