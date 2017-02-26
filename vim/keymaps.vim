" Allow either the default (\) leader key, or the more commonly used leader key (,).
" FIXME: Sadly, this doesn't work in some situations.
"nmap , <leader>
nmap , \

" Allow either default (:) or easier-to-type option (;) to start command-line mode.
nnoremap ; :

" Handle several flavors of cursor keys.
map  <Esc>[7~ <Home>
imap <Esc>[7~ <Home>
map  <Esc>OH  <Home>
imap <Esc>OH  <Home>
map  <Esc>[H  <Home>
imap <Esc>[H  <Home>
map  <Esc>OF  <End>
imap <Esc>OF  <End>
map  <Esc>[F  <End>
imap <Esc>[F  <End>

map  <Esc>[1;2A <S-Up>
imap <Esc>[1;2A <S-Up>
map  <Esc>[1;2B <S-Down>
imap <Esc>[1;2B <S-Down>
map  <Esc>[1;2C <S-Right>
imap <Esc>[1;2C <S-Right>
map  <Esc>[1;2D <S-Left>
imap <Esc>[1;2D <S-Left>
map  <Esc>[1;2H <S-Home>
imap <Esc>[1;2H <S-Home>
map  <Esc>[1;2F <S-End>
imap <Esc>[1;2F <S-End>

" Make shifted cursor keys work, to select text.
nmap <S-Up>    v<Up>
nmap <S-Down>  v<Down>
nmap <S-Left>  v<Left>
nmap <S-Right> v<Right>
nmap <S-Home>  v<Home>
nmap <S-End>   v<End>
vmap <S-Up>    <Up>
vmap <S-Down>  <Down>
vmap <S-Left>  <Left>
vmap <S-Right> <Right>
vmap <S-Home>  <Home>
vmap <S-End>   <End>

" Handle Control+Shift cursors keys.
nmap <C-S-Right> vE
vmap <C-S-Right> E
nmap <C-S-Left>  lvB
vmap <C-S-Left>  B


" Handle CUA-style cut and paste. (<S-Del> = Cut, <C-Insert> = Copy, <S-Insert> = Paste)
map  <Esc>[3;2~ <S-Del>
imap <Esc>[3;2~ <S-Del>
map  <Esc>[2;5~ <C-Insert>
imap <Esc>[2;5~ <C-Insert>
map  <Esc>[2;2~ <S-Insert>
imap <Esc>[2;2~ <S-Insert>
" Adapted from http://vim.cybermirror.org/runtime/mswin.vim
" NOTE: If nothing is selected (not in visual mode), then a whole line is cut or copied.
" FIXME: For some reason, the <S-Insert> mappings are being overridden by Janus mappings.
map  <S-Del>    $v^"+x
imap <S-Del>    <Esc>$v^"+xi
vmap <S-Del>    "+x
map  <C-Insert> $v^"+y
imap <C-Insert> <Esc>$v^"+yi
vmap <C-Insert> "+y
map  <S-Insert> "+gP
imap <S-Insert> <Esc>"+gPi
cmap <S-Insert> <C-R>+

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

" Tab in visual (or select) mode indents the selected block (and keeps it selected).
vnoremap <Tab>   >gv
vnoremap <S-Tab> <gv

" Backspace in Visual mode deletes selection.
"
vnoremap <BS> d

" Control+A is Select All.
"
noremap  <C-A>  gggH<C-O>G
inoremap <C-A>  <C-O>gg<C-O>gH<C-O>G
cnoremap <C-A>  <C-C>gggH<C-O>G
onoremap <C-A>  <C-C>gggH<C-O>G
snoremap <C-A>  <C-C>gggH<C-O>G
xnoremap <C-A>  <C-C>ggVG

" Control+S saves the current file (if it's been changed).
"
noremap  <C-S>  :update<CR>
vnoremap <C-S>  <C-C>:update<CR>
inoremap <C-S>  <C-O>:update<CR>

" Control+Z is Undo, in Normal and Insert mode.
"
noremap  <C-Z>  u
inoremap <C-Z>  <C-O>u

" F2 inserts the date and time at the cursor.
"
inoremap <F2>   <C-R>=strftime("%c")<CR>
nmap     <F2>   a<F2><Esc>

" F7 formats the current/highlighted paragraph.
"
" XXX: Consider changing this to gwap to maintain logical cursor position.
"
nnoremap <F7>   gqap
inoremap <F7>   <C-O>gqap
vnoremap <F7>   gq

" Shift+F7 joins all lines of the current paragraph or highlighted block
" into a single line.
"
nnoremap <S-F7>  vipJ
inoremap <S-F7>  <Esc>vipJi
vnoremap <S-F7>  J

" Draw lines of dashes or equal signs below us based on the length of the current line
"
"   yy      Yank whole line
"   p       Put line below current line
"   ^       Move to beginning of line
"   v$      Visually highlight to end of line
"   r-      Replace highlighted portion with dashes / equal signs
"   j       Move down one line
"   a       Return to Insert mode
"
" XXX: Convert this to a function and make the symbol a parameter.
" XXX: Consider making abbreviations/mappings for ---<CR> and ===<CR>
"
inoremap <C-U>- <Esc>yyp^v$r-ja
inoremap <C-U>= <Esc>yyp^v$r=ja

" Control+Hyphen (yes, I know it says underscore) repeats the character above
" the cursor.
"
inoremap <C-_>  <C-Y>

" Center the display line after searches. (This makes it *much* easier to see
" the matched line.)
"
" More info: http://www.vim.org/tips/tip.php?tip_id=528
"
nnoremap n   nzz
nnoremap N   Nzz
nnoremap *   *zz
nnoremap #   #zz
nnoremap g*  g*zz
nnoremap g#  g#zz

" Make page-forward and page-backward work in insert mode.
"
imap <C-F>  <C-O><C-F>
imap <C-B>  <C-O><C-B>

" Q formats the current/highlighted paragraph.
nnoremap Q  gwap
xnoremap Q  gw
vnoremap Q  gw

" Make page-forward and page-backward work in insert mode.
"
inoremap <C-F>  <C-O><C-F>
inoremap <C-B>  <C-O><C-B>

" Turn On/Off NERDTree
map <leader>n :NERDTreeToggle<CR>

" Unimpaired configuration
" Bubble single lines
nmap <C-k> [e==
nmap <C-j> ]e==
" Bubble multiple lines
vmap <C-k> [egv==
vmap <C-j> ]egv==

" Movement up and down when lines are wrapped
imap <silent> <Down> <C-o>gj
imap <silent> <Up> <C-o>gk
nmap <silent> <Down> gj
nmap <silent> <Up> gk

" Gundo configuration
nmap <F5> :GundoToggle<CR>
imap <F5> <ESC>:GundoToggle<CR>

" ZoomWin configuration
map <Leader><Leader> :ZoomWin<CR>

" CTags
map <Leader>rt :!ctags --extra=+f -R *<CR><CR>
map <C-\> :tnext<CR>

map <Leader>nf :NERDTreeFind<CR>

inoremap <M-o>       <Esc>o
inoremap <C-j>       <Down>
let g:ragtag_global_maps = 1

let g:SuperTabDefaultCompletionType = "context"

let g:user_zen_expandabbr_key = '<c-z>'

" Mapping for toggling between block wrappers
let g:blockle_mapping = '<Leader>bl'

" Toggle open the tags list window
nnoremap <silent> <F8> :TlistToggle<CR>

" Ctrl-Shift-F for Ack
  map <C-F> :Ack! ""<left>

" Alt-/ to toggle comments
  map <A-/> <plug>NERDCommenterToggle<CR>
  imap <A-/> <Esc><plug>NERDCommenterToggle<CR>i
  map <Esc>/  <plug>NERDCommenterToggle<CR>
  imap <Esc>/  <Esc><plug>NERDCommenterToggle<CR>i

" Alt-][ to increase/decrease indentation
  vmap <A-]> >gv
  vmap <A-[> <gv

" Map j/k combos to get out of insert mode
inoremap jk <esc>l
inoremap kj <esc>l
inoremap jj <esc>l
inoremap kk <esc>l

" Git Gutter Commands
let g:gitgutter_highlight_lines = 1
let g:gitgutter_enabled = 0
nmap <leader>gg :GitGutterToggle<CR>

" Fugitive
nmap <leader>gs :Gstatus<CR>
nmap <leader>gr :Gread<CR>:w<CR>
nmap <leader>gp :Git push origin HEAD<CR>

" Ruby helpers
nmap <leader>rs :w<CR>:! rspec %<CR>
nmap <leader>r :w<CR>:! ruby %<CR>
nmap <leader><leader>r :w<CR>:! ruby -Itest %<CR>

" spell check
nmap <leader>sc :setlocal spell! spelllang=en_us<CR>

" quick save
nmap <leader>s :w<CR>
inoremap <leader>s <ESC>:w<CR>
