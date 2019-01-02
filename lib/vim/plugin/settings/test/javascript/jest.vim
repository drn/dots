function! test#javascript#jest#build_position(type, position) abort
  if a:type ==# 'nearest'
    let name = s:nearest_test(a:position)
    if !empty(name)
      let name = '-t '.shellescape(name, 1)
    endif
    return ['--no-coverage', name, '-u', a:position['file']]
  elseif a:type ==# 'file'
    return ['--no-coverage', '-u', a:position['file']]
  else
    return []
  endif
endfunction

function! test#javascript#jest#executable() abort
  return 'yarn test'
endfunction
