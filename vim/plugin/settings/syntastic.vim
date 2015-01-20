" Override syntastic symbols
let g:syntastic_warning_symbol='☿'
let g:syntastic_error_symbol='☿'
let g:syntastic_style_warning_symbol='☿'
let g:syntastic_style_error_symbol='☿'
" Disable syntastic checking on save and quit
let g:syntastic_check_on_wq=0
" Use current rbenv ruby version
let g:syntastic_ruby_exec = '~/.rbenv/shims/ruby'
