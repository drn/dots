" Manually run syntax checking in case syntastic borks
map <leader>S :w !ruby -c<CR>

""" Abbreviations
iabbr rpry binding.pry_remote '0.0.0.0'
iabbr pry binding.pry
iabbr Arb ActiveRecord::Base
iabbr spechead require 'rails_helper'
