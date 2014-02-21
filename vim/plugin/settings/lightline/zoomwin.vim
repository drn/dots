" ZoomWin statusline indicator
function! LightlineZoomWinIndicator()
  if exists('g:lightline.zoomwin_status')
    return '✫'
  else
    return ''
  endif
endfunction

" keep track of ZoomWin state
function! LightlineZoomWinCallback(state)
  if a:state
    let g:lightline.zoomwin_status = 1
  else
    silent! unlet g:lightline.zoomwin_status
  endif
endfunction

" Set ZoomWin state callback function
let g:ZoomWin_funcref = function("LightlineZoomWinCallback")
