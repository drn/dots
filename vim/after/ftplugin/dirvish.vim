" fix fugitive#detect issue
" https://github.com/justinmk/vim-dirvish/issues/160
autocmd! dirvish_ftdetect FileType dirvish

" unmap default clear arglist mapping
nunmap <buffer> x
xunmap <buffer> x
nnoremap <buffer> x :Shdo  {}<Left><Left><Left>
xnoremap <buffer> x :Shdo  {}<Left><Left><Left>
