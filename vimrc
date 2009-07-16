" Turn off vi backwards-compatibility junk.
set nocompatible

" Use UTF-8 encoding.
set encoding=utf-8

" Turn on syntax highlighting if terminal can handle it.
if has('syntax') && (&t_Co > 2)
  syntax on
  colorscheme elflord " Other acceptable themes: ron 
endif

" Enable a status line that displays the current cursor position. TODO: Add more to the status line.
set ruler

" New lines should use same indentation as previous line, or "do the right thing".
set autoindent
set smartindent

" Make cursor briefly jump to matching braces/parentheses/brackets.
set showmatch

" Hard tabs are 8 characters.
set tabstop=8

" Use 4 spaces when to indent, but make it *feel* like there are hard tabs.
set shiftwidth=4
set softtabstop=4

" Never use hard tabs.
set expandtab
set smarttab

" Show periods in place of whitespace at end of line. Show double-chevron in place of hard tabs.
" TODO: Use UTF-8 characters here. (Can't get them to work in PuTTY.)
set listchars=tab:>>,trail:. " NOTE: We're unsetting eol here 
set list

" Backspace can go across newlines.
set backspace=1
" Wrap cursor on backspace, left cursor
set whichwrap=b,<,[

" Use visual bell instead of beeping.
set visualbell

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


" These are from http://www.vi-improved.org/vimrc.php
"set autochdir " always switch to the current file directory 
set clipboard+=unnamed " share windows clipboard
set wildmenu " turn on command line completion wild style
" ignore these list file extensions
set wildignore=*.dll,*.o,*.obj,*.bak,*.exe,*.pyc,*.jpg,*.gif,*.png
set wildmode=list:longest " turn on wild mode huge list
" set cursorcolumn " highlight the current column
set cursorline " highlight current line
set matchtime=5 " how many tenths of a second to blink matching brackets
set statusline=%F%m%r%h%w[%L][%{&ff}]%y[%p%%][%04l,%04v]
"              | | | | |  |   |      |  |     |    |
"              | | | | |  |   |      |  |     |    + current
"              | | | | |  |   |      |  |     |       column
"              | | | | |  |   |      |  |     +-- current line
"              | | | | |  |   |      |  +-- current % into file
"              | | | | |  |   |      +-- current syntax in
"              | | | | |  |   |          square brackets
"              | | | | |  |   +-- current fileformat
"              | | | | |  +-- number of lines
"              | | | | +-- preview flag in square brackets
"              | | | +-- help flag in square brackets
"              | | +-- readonly flag in square brackets
"              | +-- rodified flag in square brackets
"              +-- full path to file in the buffer
" ruby standard 2 spaces, always
au BufRead,BufNewFile *.rb,*.rhtml set shiftwidth=2
au BufRead,BufNewFile *.rb,*.rhtml set softtabstop=2
if has("gui_running")
  set mousehide " hide the mouse cursor when typing
endif




" These are from http://www.hermann-uwe.de/files/vimrc
set nocompatible        " Disable vi compatibility.
set history=100         " Number of lines of command line history.
set undolevels=200      " Number of undo levels.
set textwidth=0         " Don't wrap words by default.
set showcmd             " Show (partial) command in status line.
set showmatch           " Show matching brackets.
set showmode            " Show current mode.
set ruler               " Show the line and column numbers of the cursor.
set ignorecase          " Case insensitive matching.
set modeline            " Enable modeline.
set esckeys             " Cursor keys in insert mode.
set gdefault            " Use 'g' flag by default with :s/foo/bar/.
set magic               " Use 'magic' patterns (extended regular expressions).
set hlsearch            " Highlight search matches.
" Allow backspacing over everything in insert mode.
set backspace=indent,eol,start
" Path/file expansion in colon-mode.
set wildmode=list:longest
set wildchar=<TAB>

" Got these from http://stripey.com/vim/vimrc.html:
" use "[RO]" for "[readonly]" to save space in the message line:
set shortmess+=r
" Have the mouse enabled all the time:
"set mouse=a
" don't make it look like there are line breaks where there aren't:
set nowrap
set shiftround
" normally don't automatically format `text' as it is typed, IE only do this
" with comments, at 79 characters:
set formatoptions-=t
set textwidth=79
" enable filetype detection:
filetype on
" in human-language files, automatically format everything at 72 chars:
autocmd FileType mail,human set formatoptions+=t textwidth=72
" for C-like programming, have automatic indentation:
autocmd FileType c,cpp,slang set cindent
" for actual C (not C++) programming where comments have explicit end
" characters, if starting a new line in the middle of a comment automatically
" insert the comment leader characters:
autocmd FileType c set formatoptions+=ro
" for HTML, generally format text, but if a long line has been created leave it
" alone when editing:
autocmd FileType html set formatoptions+=tl
" in makefiles, don't expand tabs to spaces, since actual tab characters are
" needed, and have indentation at 8 chars to be sure that all indents are tabs
" (despite the mappings later):
autocmd FileType make set noexpandtab shiftwidth=8
" make searches case-insensitive, unless they contain upper-case letters:
set ignorecase
set smartcase
set infercase
" assume the /g flag on :s substitutions to replace all matches in a line:
set gdefault
" have <Tab> (and <Shift>+<Tab> where it works) change the level of
" indentation:
inoremap <Tab> <C-T>
inoremap <S-Tab> <C-D>
" [<Ctrl>+V <Tab> still inserts an actual tab character.]


"------------------------------------------------------------------------------
" Abbreviations.
"------------------------------------------------------------------------------
iab beacuse    because
iab becuase    because
iab cna        can
iab chnage     change
iab chnages    changes
iab chnaged    changed
iab ChnageLog  ChangeLog
iab defualt    default
iab differnt   different
iab diffrent   different
iab emial      email
iab figth      fight
iab figther    fighter
iab fro        for
iab fucntion   function
iab ahve       have
iab homepgae   homepage
iab logifle    logfile
iab lokk       look
iab lokking    looking
iab mial       mail
iab Mial       Mail
iab miantainer maintainer
iab amke       make
iab mroe       more
iab nwe        new
iab recieve    receive
iab recieved   received
iab erturn     return
iab retrun     return
iab retunr     return
iab seperate   separate
iab shoudl     should
iab soem       some
iab taht       that
iab thta       that
iab teh        the
iab tehy       they
iab truely     truly
iab waht       what
iab wiht       with
iab whic       which
iab whihc      which
iab yuo        you
iab databse    database
iab versnio    version
iab flase      false

ab lnx         Linux
ab cb          Craig Buchek

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif


if filereadable(expand("~/.vim/abbreviations"))
  source ~/.vim/abbreviations
endif

