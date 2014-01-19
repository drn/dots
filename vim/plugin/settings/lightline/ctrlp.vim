function! LightlineMode()
  let fname = expand('%:t')
  return fname == 'ControlP' ? 'CtrlP' .
        \ (exists('g:lightline.ctrlp_filecount') ? ' ('.g:lightline.ctrlp_filecount.')' : '' ) :
        \ fname == '__Gundo__' ? 'Gundo' :
        \ fname == '__Gundo_Preview__' ? 'Gundo Preview' :
        \ fname =~ 'NERD_tree' ? 'NERDTree' :
        \ winwidth(0) > 60 ? lightline#mode() : ''
endfunction

let g:ctrlp_status_func = {
\ 'main': 'LightlineCtrlPStatusMain',
\ 'prog': 'LightlineCtrlPStatusProg',
\ }

function! LightlineCtrlPMark()
  if expand('%:t') =~ 'ControlP'
    call lightline#link('iR'[g:lightline.ctrlp_regex])
    return lightline#concatenate(
          \  [
          \    g:lightline.ctrlp_prev,
          \    g:lightline.ctrlp_item,
          \    g:lightline.ctrlp_next
          \  ],
          \  0
          \)
  else
    return ''
  endif
endfunction

function! LightlineCtrlPStatusMain(focus, byfname, regex, prev, item, next, marked)
  let g:lightline.ctrlp_regex = a:regex
  let g:lightline.ctrlp_prev = a:prev
  let g:lightline.ctrlp_item = a:item
  let g:lightline.ctrlp_next = a:next
  let g:lightline.ctrlp_marked = a:marked
  unlet g:lightline.ctrlp_filecount
  return lightline#statusline(0)
endfunction

function! LightlineCtrlPStatusProg(str)
  let g:lightline.ctrlp_filecount = a:str
  return lightline#statusline(0)
endfunction

