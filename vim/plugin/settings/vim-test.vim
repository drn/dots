" custom mappings
nmap <leader>r :TestFile<cr>
nmap <leader>R :TestNearest<cr>
let test#strategy = 'vimux'
" override default jest executable
" -u updates snapshots
let g:test#javascript#jest#executable = 'yarn test -u --no-watch'
