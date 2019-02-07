" configure and color the color column
if exists('+colorcolumn')
  set colorcolumn=50
  hi ColorColumn guibg=#444444
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>50v.\+', -1)
endif

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%73v.\+/
