function! LightlineMode()
  let fname = expand('%:t')
  return fname == 'ControlP' ? 'CtrlP' :
        \ fname == '__Gundo__' ? 'Gundo' :
        \ fname == '__Gundo_Preview__' ? 'Gundo Preview' :
        \ fname =~ 'NERD_tree' ? 'NERDTree' :
        \ winwidth(0) > 60 ? lightline#mode() : ''
endfunction

function! LightlineModified()
  return &ft !~? 'help' && &modified ? '[+]' : ''
endfunction

function! LightlineReadonly()
  return &ft !~? 'help' && &readonly ? "\uf456" : ''
endfunction

function! LightlineFilename()
  let fname = expand('%:t')
  return fname == 'ControlP' ? '' :
        \  fname =~ '__Gundo\|NERD_tree' ? '' :
        \  ('' != LightlineReadonly() ? LightlineReadonly() . ' ' : '') .
        \  ('' != fname ? fname : '[No Name]') .
        \  ('' != LightlineModified() ? ' ' . LightlineModified() : '')
endfunction

function! LightlineInactiveFilename()
  let path = expand('%:p')
  if '' != path
    let basepath = substitute(path, '[^\/]*\/[^\/]*$','','')
    let tail = substitute(path, basepath, '', '')
    return ('' != tail ? '../' . tail : expand('%:t')) .
          \  ('' != LightlineModified() ? ' ' . LightlineModified() : '')
  else
    return '[No Name]' .
          \  ('' != LightlineModified() ? ' ' . LightlineModified() : '')
  endif
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

function! LightlineFilebom()
  return winwidth(0) > 70 ? (&bomb ? "[\ufb8f]" : '') : ''
endfunction
