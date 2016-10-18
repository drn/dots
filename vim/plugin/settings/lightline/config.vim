" Lightline.vim Configuration

let g:lightline = {
\   'colorscheme': 'jellybeans',
\   'active': {
\     'left': [
\       [ 'mode', 'paste' ],
\       [ 'fugitive', 'ctrlp', 'filename', 'zoompane' ]
\     ],
\     'right': [
\       [ 'ale', 'lineinfo' ],
\       [ 'percent' ],
\       [ 'fileformat', 'fileencoding', 'filetype' ]
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
\     'ctrlp': 'LightlineCtrlP',
\     'mode': 'LightlineMode',
\     'zoompane': 'LightlineZoomPaneIndicator'
\   },
\   'component_expand': {
\     'ale': 'ALEGetStatusLine'
\   },
\   'component_type': {
\     'ale': 'error'
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
