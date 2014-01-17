" options

" always show status line
set laststatus=2
" hide duplicate mode descriptions
set noshowmode
" set font
set guifont=Menlo\ for\ Powerline:h13

" Lightline.vim Configuration

let g:lightline = {
\   'colorscheme': 'jellybeans',
\   'active': {
\     'left': [
\       [ 'mode', 'paste' ],
\       [ 'fugitive', 'filename' ],
\       [ 'ctrlpmark' ]
\     ],
\     'right': [
\       [ 'syntastic', 'lineinfo' ],
\       ['percent'],
\       [ 'fileformat', 'fileencoding', 'filetype' ]
\     ]
\   },
\   'component_function': {
\     'readonly': 'LightlineReadonly',
\     'modified': 'LightlineModified',
\     'fugitive': 'LightlineFugitive',
\     'filename': 'LightlineFilename',
\     'fileformat': 'LightlineFileformat',
\     'filetype': 'LightlineFiletype',
\     'fileencoding': 'LightlineFileencoding',
\     'ctrlpmark': 'LightlineCtrlPMark',
\     'mode': 'LightlineMode'
\   },
\   'component_expand': {
\     'syntastic': 'SyntasticStatuslineFlag'
\   },
\   'component_type': {
\     'syntastic': 'error'
\   },
\   'component': {
\     'lineinfo': '⭡%3l:%-2v'
\   },
\   'separator': {
\     'left': '⮀',
\     'right': '⮂'
\   },
\   'subseparator': {
\     'left': '⮁',
\     'right': '⮃'
\   }
\ }


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

function! LightlineFugitive()
  if &ft !~? 'Gundo\|NERD' && exists("*fugitive#head")
    let _ = fugitive#head()
    return strlen(_) ? '⭠ '._ : ''
  endif
  return ''
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

function! LightlineMode()
  let fname = expand('%:t')
  return fname == 'ControlP' ? 'CtrlP' :
        \ fname == '__Gundo__' ? 'Gundo' :
        \ fname == '__Gundo_Preview__' ? 'Gundo Preview' :
        \ fname =~ 'NERD_tree' ? 'NERDTree' :
        \ winwidth(0) > 60 ? lightline#mode() : ''
endfunction

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

let g:ctrlp_status_func = {
\ 'main': 'CtrlPStatusFunc_1',
\ 'prog': 'CtrlPStatusFunc_2',
\ }

function! CtrlPStatusFunc_1(focus, byfname, regex, prev, item, next, marked)
  let g:lightline.ctrlp_regex = a:regex
  let g:lightline.ctrlp_prev = a:prev
  let g:lightline.ctrlp_item = a:item
  let g:lightline.ctrlp_next = a:next
  let g:lightline.ctrlp_marked = a:marked
  return lightline#statusline(0)
endfunction

function! CtrlPStatusFunc_2(str)
  return lightline#statusline(0)
endfunct

augroup AutoSyntastic
  autocmd!
  autocmd BufWritePost * call s:syntastic()
augroup END
function! s:syntastic()
  SyntasticCheck
  call lightline#update()
endfunction

