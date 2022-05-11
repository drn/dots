function! LightlineFugitive()
  if &ft !~? 'Gundo\|NERD' && exists("*FugitiveHead")
    let _ = FugitiveHead()
    return strlen(_) ? "\ue0a0 "._ : ''
  endif
  return ''
endfunction
