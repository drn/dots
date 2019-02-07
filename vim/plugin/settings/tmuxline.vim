let g:tmuxline_powerline_separators = 0
let g:tmuxline_separators = {
\   'left'      : '⮀',
\   'left_alt'  : '⮁',
\   'right'     : '⮂',
\   'right_alt' : '⮃',
\   'space'     : ' '
\ }
let g:tmuxline_preset = {
\   'a'     : ['#S', '#W', '#F'],
\   'b'     : '#(whoami)',
\   'c'     : "#(uptime | sed 's/.*up //' | sed 's/, . user.*//')",
\   'win'   : ['#I', '#W'],
\   'cwin'  : ['#I', '#W'],
\   'x'     : '#(whoami)',
\   'y'     : ['%I:%M%P', '%a', '%Y'],
\   'z'     : '@#H'
\ }
