" Set Missing Filetypes
augroup filetypedetect
  au BufRead,BufNewFile gitconfig set filetype=gitconfig
  au BufRead,BufNewFile *.cfg set filetype=sh
  au BufRead,BufNewFile pryrc set filetype=ruby
  au BufRead,BufNewFile scratch-pad set filetype=txt
  au BufRead,BufNewFile *.arb set filetype=ruby
  au BufRead,BufNewFile Fastfile set filetype=ruby
  au BufRead,BufNewFile *_spec.rb set filetype=ruby.rspec
  au BufRead,BufNewFile *.keras set filetype=python
  au BufNewFile,BufRead *.tsx set filetype=typescript
  au BufNewFile,BufRead *.mdx set filetype=markdown
augroup END

" trim all whitespace on save
autocmd BufWritePre * call TrimWhitespace()
function TrimWhitespace()
  let line = line('.')
  let col = col('.')
  " trim trailing whitespace
  execute('%s/\s\+$//e')
  " preserve cursor position
  call cursor(line, col)
  " if gitcommit, trim leading whitespace of first line
  if &filetype == 'gitcommit'
    execute('0s/^\s\+//e')
  endif
endfunction

" always display sign column
autocmd BufEnter * sign define dummy
autocmd BufEnter * execute 'sign place 9999 line=1 name=dummy buffer=' . bufnr('')

" automatically redraw screen after save
autocmd BufWritePost * :redraw!

" Automatically close QuickFix window
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

" Automatically adjust quickfix window height
"   https://gist.github.com/juanpabloaj/5845848
au FileType qf call AdjustWindowHeight(3, 18)
function! AdjustWindowHeight(minheight, maxheight)
  let l = 1
  let n_lines = 0
  let w_width = winwidth(0)
  while l <= line('$')
    " number to float for division
    let l_len = strlen(getline(l)) + 0.0
    let line_width = l_len/w_width
    let n_lines += float2nr(ceil(line_width))
    let l += 1
  endw
  exe max([min([n_lines, a:maxheight]), a:minheight]) . "wincmd _"
endfunction
