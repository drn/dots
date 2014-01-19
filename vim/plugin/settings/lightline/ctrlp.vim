" CtrlP Status Line Section
"   Returns either the ctrlp_status or a listing of the previous, current, and
"   next search modes.
function! LightlineCtrlP()
  if expand('%:t') =~ 'ControlP'
    if exists('g:lightline.ctrlp_status')
      return g:lightline.ctrlp_status
    else
      return lightline#concatenate(
            \  [
            \    g:lightline.ctrlp_prev,
            \    g:lightline.ctrlp_item,
            \    g:lightline.ctrlp_next
            \  ],
            \  0
            \)
    endif
  else
    return ''
  endif
endfunction

" Set CtrlP statusline callback functions
let g:ctrlp_status_func = {
\ 'main': 'LightlineCtrlPStatusMain',
\ 'prog': 'LightlineCtrlPStatusProgress',
\ }

" Main statusline callback function
" Arguments:
"   a:focus   : The focus of the prompt: "prt" or "win".
"   a:byfname : In filename mode or in full path mode: "file" or "path".
"   a:regex   : In regex mode: 1 or 0.
"   a:prev    : The previous search mode.
"   a:item    : The current search mode.
"   a:next    : The next search mode.
"   a:marked  : The number of marked files, or a comma separated list of
"               the marked filenames.
function! LightlineCtrlPStatusMain(focus, byfname, regex, prev, item, next, marked)
  let g:lightline.ctrlp_regex = a:regex
  let g:lightline.ctrlp_prev = a:prev
  let g:lightline.ctrlp_item = a:item
  let g:lightline.ctrlp_next = a:next
  let g:lightline.ctrlp_marked = a:marked
  unlet g:lightline.ctrlp_status
  return lightline#statusline(0)
endfunction

" Progress statusline callback function
" Arguments:
"   a:status  : Either the number of files scanned so far, or a string
"               indicating the current directory is being scanned with
"               a user_command
function! LightlineCtrlPStatusProgress(status)
  let g:lightline.ctrlp_status = a:status
  return lightline#statusline(0)
endfunction

