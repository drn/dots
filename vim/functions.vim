" Move line up
function! MoveLineUp()
  if line('.') != 1
    exec "move -2"
  endif
endfunction
nnoremap <silent> <leader>w :call MoveLineUp()<cr>

" Move line down
function! MoveLineDown()
  if line('.') != line('$')
    exec "move +1"
  endif
endfunction
nnoremap <silent> <leader>s :call MoveLineDown()<cr>

" Delete Inactive Buffers
function! CloseInactiveBuffers()
  let tablist = []
  for i in range(tabpagenr('$'))
    call extend(tablist, tabpagebuflist(i + 1))
  endfor
  for i in range(1, bufnr('$'))
    if bufexists(i) && !getbufvar(i,"&mod") && index(tablist, i) == -1
      silent exec 'bwipeout' i
    endif
  endfor
  echomsg 'Closed inactive buffers.'
endfunction
nnoremap <leader>q :call CloseInactiveBuffers()<cr>

" Reindent File
function Reindent()
  let line = line('.')
  let col = col('.')
  execute "normal! ggVG="
  call cursor(line, col)
endfunction
nnoremap <silent> <leader>= :call Reindent()<CR>

function ProfileStart()
  profile start profile.log
  profile func *
  profile file *
  echomsg "Starting Profiling..."
endfunction
noremap <silent> <leader>d> :call ProfileStart()<CR>

function ProfileEnd()
  echomsg "Ending Profiling... Open profile.log for details."
  sleep 2
  profile pause
  noautocmd qall!
endfunction
noremap <silent> <leader>d< :call ProfileEnd()<CR>

function Enter()
  cd %:h
  echomsg "Set working directory to " . getcwd()
endfunction
noremap <silent> <leader>e :call Enter()<CR>

function JsonFormat()
  exec "'<,'>!python -m json.tool"
  call Reindent()
endfunction
vmap <silent> F :call JsonFormat()<CR>

function ToggleZoomPane()
  let wincount = winnr('$')
  if wincount > 1
    tab split
  else
    let tabcount = tabpagenr('$')
    let currenttab = tabpagenr()
    if tabcount > 1 && currenttab == tabcount
      quit
    end
  end
endfunction
nmap <silent> ;z :call ToggleZoomPane()<CR>

function! GlobalReplace()
  let find = input('Find: ')
  if len(find) == 0
    return
  endif
  let replace = input('Replace: ')
  if len(replace) == 0
    return
  endif
  let filematcher = input('File Matcher (**/*.rb): ')
  if len(filematcher) == 0
    return
  endif
  execute 'args `grep -nl ' . find . ' ' . filematcher . '`'
  execute 'argdo %s/' . find . '/' . replace . '/ge | w'
endfunction
command! GlobalReplace call GlobalReplace()

function Strip(string)
  return substitute(a:string, '\n', '', '')
endfunction

" Return the Github URL of the current repository
function GitRepoUrl()
  let url = system("git config --get remote.upstream.url")
  if url == ""
    let url = system("git config --get remote.origin.url")
  endif
  let url = substitute(Strip(url), '\.git$', '', '')
  let url = substitute(url, 'git@github.com:', '', '')
  let url = substitute(url, 'https://github.com/', '', '')
  return 'https://github.com/' . url
endfunction

" Return the github line suffix of a standard file
function LineSuffixStandard()
  let line = line('.')
  if line == 1 | return '' | endif
  return '#L' . line
endfunction

" Return the github line suffix of a markdown file
function LineSuffixMarkdown()
  " backsearch to identify matching titles without changing cursor position
  let line = search('^#\{1,4} .*$', 'bn')
  if line == 0 | return '' | endif
  let contents = tolower(getline(line))
  " replace leading #s
  let l:key = substitute(contents, '^#\{1,4} ', '', '')
  " replace spaces with -s
  let l:key = substitute(l:key, ' ', '-', 'g')
  " strip &, (, ) symbols
  let l:key = substitute(l:key, '[&()]', '', 'g')
  return '#' . l:key
endfunction

" Return the current line number if the format '#L'. Return an empty string
" if on the first line of the file.
function LineSuffix()
  if &filetype == 'markdown'
    return LineSuffixMarkdown()
  else
    return LineSuffixStandard()
  endif
endfunction

" Return full Github URL of the current file on the current line
function GitUrl()
  " determine relative file path
  let filepath = expand("%:p")
  let repopath = Strip(system("git rev-parse --show-toplevel"))
  let path = substitute(filepath, repopath, '', '')

  " tree url
  if path[strlen(path)-1] == "/"
    return GitRepoUrl() . '/tree/master' . path
  end

  " file url
  if path != '/README.md'
    return GitRepoUrl() . '/blob/master' . path . LineSuffix()
  end

  " base readme
  return GitRepoUrl() . LineSuffix()
endfunction

" Opens the GitUrl() in a browser
function! Gopen()
  let url = GitUrl()
  call system('open ' . url)
  echomsg 'Opened ' . url
endfunction
command! Gopen call Gopen()
command! Go call Gopen()

" Copies the GitUrl() to the clipboard
function! Gcopy()
  let url = GitUrl()
  call system('echo -n ' . url . ' | pbcopy')
  echomsg 'Copied ' . url
endfunction
command! Gcopy call Gcopy()
command! Gc call Gcopy()

" Alias Gb to Gblame
command! Gb Git blame

" Open gitk to the current file
function! Gitk()
  call system('gitk ' . expand("%:p") . '&')
endfunction
command! Gitk call Gitk()

" Toggles Gemfile Nucleus branch between master and branch
function! NucleusReplace()
  let l:filename = expand('%:t')
  " only trigger for Gemfile
  if l:filename != 'Gemfile' | return | endif
  " search for NUCLEUS_BRANCH line number
  let l:line = search('NUCLEUS_BRANCH', 'n')
  if l:line == 0 | return | endif
  " git branch and strip whitespace
  let l:branch = system('echo -n "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"')
  " determine new line contents
  let l:contents = getline(l:line)
  let l:base = system('git canonical-branch')
  let l:base = substitute(l:base, '\n\+$', '', '')
  let l:current = l:base
  let l:adjustment = l:branch
  if l:contents !~ l:base
    let l:current = l:branch
    let l:adjustment = l:base
  endif
  let l:contents = substitute(l:contents, l:current, l:adjustment, '')
  " change line contents
  echo 'Switching Nucleus from "' . l:current . '" to "' . l:adjustment . '"'
  call setline(l:line, l:contents)
endfunction
command! Nr call NucleusReplace()

au BufRead *.gif,*.png,*.jpg,*.jpeg :call DisplayImage()
function! DisplayImage()
  let filepath = expand('%:p')
  bd! | enew | call termopen("chafa \"" . filepath . "\"")
endfunction

" Auto-format JSON in file using jq
function! JQ()
  :%!jq .
endfunction
command! JQ call JQ()
