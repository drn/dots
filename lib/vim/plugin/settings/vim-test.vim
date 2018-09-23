" custom mappings
nmap <leader>r :TestFile<cr>
nmap <leader>R :TestNearest<cr>
let test#strategy = 'vimux'

function! test#javascript#jest#executable() abort
  return 'yarn test'
endfunction
