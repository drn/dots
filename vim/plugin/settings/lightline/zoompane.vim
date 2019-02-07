" ZoomPane statusline indicator
function! LightlineZoomPaneIndicator()
  let wincount = winnr('$')
  let tabcount = tabpagenr('$')
  let currenttab = tabpagenr()
  if wincount == 1 && tabcount > 1 && currenttab == tabcount
    return '✫'
  else
    return ''
  endif
endfunction
