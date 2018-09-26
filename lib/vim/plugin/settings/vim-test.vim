" custom mappings
nmap <leader>r :TestFile<cr>
nmap <leader>R :TestNearest<cr>
let test#strategy = 'vimux'

function! test#strategy#vimux(cmd) abort
  if exists('g:VimuxRunnerIndex')
    unlet g:VimuxRunnerIndex
  endif
  call VimuxClearRunnerHistory()
  let echo = 'echo -e ' . shellescape(a:cmd)
  call VimuxRunCommand(join(['shrink', 'clear', l:echo, a:cmd], '; '))
endfunction

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
