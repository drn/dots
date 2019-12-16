" credit: https://github.com/drzel/vim-line-no-indicator
function! LightlinePercentIndicator()
  let l:line_no_indicator_chars = ['⎺', '⎻', '─', '⎼', '⎽']

  " Zero index line number so 1/3 = 0, 2/3 = 0.5, and 3/3 = 1
  let l:current_line = line('.') - 1
  let l:total_lines = line('$') - 1
  let l:percent = 0

  if l:current_line == 0
    let l:index = 0
  elseif l:current_line == l:total_lines
    let l:index = -1
    let l:percent = 100
  else
    let l:line_no_fraction = 1.0 * l:current_line / l:total_lines
    let l:index = float2nr(l:line_no_fraction * len(l:line_no_indicator_chars))
    let l:percent = float2nr(l:line_no_fraction * 100)
  endif

  return l:line_no_indicator_chars[l:index] . ' ' . l:percent . '%'
endfunction
