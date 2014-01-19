let g:startify_custom_header = [
\ "   /$$$$$$                                          /$$",
\ "  /$$__  $$                                        |__/",
\ " | $$  \\__/  /$$$$$$  /$$$$$$$   /$$$$$$  /$$   /$$ /$$ /$$$$$$$   /$$$$$$",
\ " |  $$$$$$  |____  $$| $$__  $$ /$$__  $$| $$  | $$| $$| $$__  $$ /$$__  $$",
\ "  \\____  $$  /$$$$$$$| $$  \\ $$| $$  \\ $$| $$  | $$| $$| $$  \\ $$| $$$$$$$$",
\ "  /$$  \\ $$ /$$__  $$| $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$| $$_____/",
\ " |  $$$$$$/|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$/| $$| $$  | $$|  $$$$$$$",
\ "  \\______/  \\_______/|__/  |__/ \\____  $$ \\______/ |__/|__/  |__/ \\_______/",
\ "                                /$$  \\ $$",
\ "                               |  $$$$$$/",
\ "                   /$$$$$$$     \\______/",
\ "                  | $$__  $$",
\ "                  | $$  \\ $$  /$$$$$$  /$$$$$$$   /$$$$$$",
\ "                  | $$$$$$$/ |____  $$| $$__  $$ /$$__  $$",
\ "                  | $$__  $$  /$$$$$$$| $$  \\ $$| $$$$$$$$",
\ "                  | $$  \\ $$ /$$__  $$| $$  | $$| $$_____/",
\ "                  | $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$",
\ "                  |__/  |__/ \\_______/|__/  |__/ \\_______/",
\ "",
\"",
\]

let g:startify_list_order = [
\ ['  Bookmarks:'],
\ 'bookmarks',
\ ['  Recently modified files in the current directory:'],
\ 'dir',
\ ['  Recently opened files:'],
\ 'files',
\ ]

let g:startify_skiplist = [
\ '^/tmp',
\ '.git/COMMIT_EDITMSG',
\ ]

let g:startify_bookmarks = [
\ '~/.vimrc',
\ '~/Development/work/thanx-web',
\ '~/Development/dotfiles',
\ '~/Development/personal/jira-cli',
\ '~/Development/work/keyword-crawler'
\ ]

let g:startify_files_number = 5

nnoremap <silent> <leader>6 :Startify<cr>
