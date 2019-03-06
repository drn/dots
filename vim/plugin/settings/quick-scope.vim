" change quick scope highlight autocmd to CursorHold instead of CursorMoved
let g:qs_lazy_highlight = 1

" Disable quick-scope in CtrlP buffers
au BufEnter ControlP let b:qs_local_disable = 1
