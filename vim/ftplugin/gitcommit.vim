" configure and color the color column
if exists('+colorcolumn')
  set colorcolumn=50
  hi ColorColumn guibg=#444444
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>50v.\+', -1)
endif
