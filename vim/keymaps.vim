" Handle several flavors of cursor keys. TODO: This only handles HOME key.
map [7~  <Home>
imap [7~ <Home>
map OH   <Home>
imap OH  <Home>
map [1~  <Home>
imap [1~ <Home>

" Home key toggles between first nonblank character on line, and first column.
" From http://vim.wikia.com/wiki/Smart_home:
" FIXME: Doesn't handle lines containing only whitespace.
noremap  <expr> <Home> (col('.') == matchend(getline('.'), '^\s*')+1 ? '0'  : '^')
imap <Home> <C-o><Home>

" have <Tab> (and <Shift>+<Tab> where it works) change the level of
" indentation:
inoremap <Tab> <C-T>
inoremap <S-Tab> <C-D>
" [<Ctrl>+V <Tab> still inserts an actual tab character.]
