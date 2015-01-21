function! s:syntaxfile()
  syntax keyword rubyGemfileMethod gemspec gem source path git group platforms env ruby
  hi def link rubyGemfileMethod Function
endfunction

function! s:syntaxlock()
  setlocal iskeyword+=-,.
  syn match gemfilelockHeading  '^[[:upper:]]\+$'
  syn match gemfilelockKey      '^\s\+\zs\S\+:'he=e-1 skipwhite nextgroup=gemfilelockRevision
  syn match gemfilelockKey      'remote:'he=e-1 skipwhite nextgroup=gemfilelockRemote
  syn match gemfilelockRemote   '\S\+' contained
  syn match gemfilelockRevision '[[:alnum:]._-]\+$' contained
  syn match gemfilelockGem      '^\s\+\zs[[:alnum:]._-]\+\%([ !]\|$\)\@=' contains=gemfilelockFound,gemfilelockMissing skipwhite nextgroup=gemfilelockVersions,gemfilelockBang
  syn match gemfilelockVersions '([^()]*)' contained contains=gemfilelockVersion
  syn match gemfilelockVersion  '[^,()]*' contained
  syn match gemfilelockBang     '!' contained
  if !empty(bundler#project())
    exe 'syn match gemfilelockFound "\<\%(bundler\|' . join(keys(s:project().paths()), '\|') . '\)\>" contained'
    exe 'syn match gemfilelockMissing "\<\%(' . join(keys(filter(s:project().versions(), '!has_key(s:project().paths(), v:key)')), '\|') . '\)\>" contained'
  else
    exe 'syn match gemfilelockFound "\<\%(\S*\)\>" contained'
  endif
  syn match gemfilelockHeading  '^PLATFORMS$' nextgroup=gemfilelockPlatform skipnl skipwhite
  syn match gemfilelockPlatform '^  \zs[[:alnum:]._-]\+$' contained nextgroup=gemfilelockPlatform skipnl skipwhite

  hi def link gemfilelockHeading  PreProc
  hi def link gemfilelockPlatform Typedef
  hi def link gemfilelockKey      Identifier
  hi def link gemfilelockRemote   String
  hi def link gemfilelockRevision Number
  hi def link gemfilelockFound    Statement
  hi def link gemfilelockMissing  Error
  hi def link gemfilelockVersion  Type
  hi def link gemfilelockBang     Special
endfunction

function! s:setuplock()
  nnoremap <silent><buffer> gf         :Bopen    <C-R><C-F><CR>
  nnoremap <silent><buffer> <C-W>f     :Bsplit   <C-R><C-F><CR>
  nnoremap <silent><buffer> <C-W><C-F> :Bsplit   <C-R><C-F><CR>
  nnoremap <silent><buffer> <C-W>gf    :Btabedit <C-R><C-F><CR>
endfunction

augroup bundler_syntax
  autocmd!
  autocmd BufNewFile,BufRead */.bundle/config set filetype=yaml
  autocmd BufNewFile,BufRead Gemfile if &filetype !=# 'ruby' | setf ruby | endif
  autocmd Syntax ruby if expand('<afile>:t') ==? 'gemfile' | call s:syntaxfile() | endif
  autocmd BufNewFile,BufRead [Gg]emfile.lock setf gemfilelock
  autocmd FileType gemfilelock set suffixesadd=.rb
  autocmd Syntax gemfilelock call s:syntaxlock()
  autocmd FileType gemfilelock    call s:setuplock()
  autocmd User Rails/Gemfile.lock call s:setuplock()
augroup END
