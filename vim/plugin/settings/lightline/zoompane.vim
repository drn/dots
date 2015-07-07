" ZoomPane statusline indicator
function! LightlineZoomPaneIndicator()
  let wincount = winnr('$')
  let tabcount = tabpagenr('$')
  if wincount == 1 && tabcount > 1
    return '✫'
  else
    return ''
  endif
endfunction
