" Lightline.vim Configuration

let g:lightline = {
\   'colorscheme': 'jellybeans',
\   'active': {
\     'left': [
\       [ 'mode', 'paste' ],
\       [ 'fugitive', 'ctrlp', 'filename', 'zoompane' ]
\     ],
\     'right': [
\       [ 'linter_checking', 'linter_errors', 'linter_warnings', 'lineinfo' ],
\       [ 'percent' ],
\       [ 'fileformat', 'fileencoding', 'filetype', 'filebom' ]
\     ]
\   },
\   'inactive': {
\     'left': [
\       [ 'inactivefilename' ]
\     ],
\     'right': [
\       [ 'lineinfo' ],
\       [ 'percent' ]
\     ]
\   },
\   'component_function': {
\     'readonly': 'LightlineReadonly',
\     'modified': 'LightlineModified',
\     'fugitive': 'LightlineFugitive',
\     'filename': 'LightlineFilename',
\     'inactivefilename': 'LightlineInactiveFilename',
\     'fileformat': 'LightlineFileformat',
\     'filetype': 'LightlineFiletype',
\     'fileencoding': 'LightlineFileencoding',
\     'filebom': 'LightlineFilebom',
\     'ctrlp': 'LightlineCtrlP',
\     'mode': 'LightlineMode',
\     'zoompane': 'LightlineZoomPaneIndicator',
\     'percent': 'LightlinePercentIndicator'
\   },
\   'component_expand': {
\     'linter_checking': 'lightline#ale#checking',
\     'linter_warnings': 'lightline#ale#warnings',
\     'linter_errors': 'lightline#ale#errors',
\     'linter_ok': 'lightline#ale#ok'
\   },
\   'component_type': {
\     'linter_checking': 'left',
\     'linter_warnings': 'warning',
\     'linter_errors': 'error',
\     'linter_ok': 'left',
\   },
\   'component': {
\     'lineinfo': '⭡ %3l:%-2v'
\   },
\   'separator': {
\     'left': '⮀',
\     'right': '⮂'
\   },
\   'subseparator': {
\     'left': '⮁',
\     'right': '⮃'
\   }
\ }
