" Use tmux as vim-slime target
let g:slime_target = 'tmux'
let g:slime_no_mappings = 1
xmap <c-c><c-c> <Plug>SlimeRegionSend
nmap <c-c><c-c> <Plug>SlimeParagraphSend
nmap <c-c>v <Plug>SlimeConfig
