function! LightlineModified()
  return &ft !~? 'help' && &modified ? '[+]' : ''
endfunction

function! LightlineReadonly()
  return &ft !~? 'help' && &readonly ? '⭤' : ''
endfunction

function! LightlineFilename()
  let fname = expand('%:t')
  return fname == 'ControlP' ? g:lightline.ctrlp_item :
        \  fname =~ '__Gundo\|NERD_tree' ? '' :
        \  ('' != LightlineReadonly() ? LightlineReadonly() . ' ' : '') .
        \  ('' != expand('%:t') ? expand('%:t') : '[No Name]') .
        \  ('' != LightlineModified() ? ' ' . LightlineModified() : '')
endfunction

function! LightlineFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LightlineFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : '?') : ''
endfunction

function! LightlineFileencoding()
  return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

