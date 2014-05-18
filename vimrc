" Turn off vi backwards-compatibility junk.
set nocompatible

" Use UTF-8 encoding.
set encoding=utf-8

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

" Use visual bell instead of beeping.
set visualbell

" Display relative line numbers, except for current line (requires vim 7.4+).
set relativenumber
set number

" Store backup and swap files in a common location.
set backupdir=~/.vim/backup
set directory=~/.vim/backup

" Make the keyboard and mouse act more like Windows.
set selection=exclusive
set selectmode=mouse,key
set mousemodel=popup
set keymodel=startsel,stopsel

" Allow shifted cursor keys to act more like Mac/Windows.
let macvim_hig_shift_movement = 1


" These are from http://www.vi-improved.org/vimrc.php
"set autochdir " always switch to the current file directory
set clipboard+=unnamed " share windows clipboard
set wildmenu " turn on command line completion wild style
" ignore these list file extensions
set wildignore=*.dll,*.o,*.obj,*.bak,*.exe,*.pyc,*.jpg,*.gif,*.png
set wildmode=list:longest " turn on wild mode huge list
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
set esckeys             " Cursor keys in insert mode.
set gdefault            " Use 'g' flag by default with :s/foo/bar/.
set magic               " Use 'magic' patterns (extended regular expressions).

" Highlight search matches, and search incrementally (as you type).
set hlsearch
set incsearch

" Path/file expansion in colon-mode.
set wildmode=list:longest
set wildchar=<TAB>

" Don't allow modelines (lines in files that will run vim commands), due to security issues and principle of least surprise.
set nomodeline
set modelines=0

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

" Use standard regular expressions, instead of weird vim regex extensions.
nnoremap / /\v
vnoremap / /\v


" Load other files.
for file_name in ["local", "packages", "commands", "filetypes", "colors", "keymaps", "abbrev"]
  let file_path = expand("~/.vim/" . file_name . ".vim")
  if filereadable(file_path)
    exe "source " . file_path
  endif
endfor

" Wrap cursor on backspace and left and right cursor movements in all modes.
" NOTE: Something before this is turning this feature off.
set backspace=indent,eol,start
set whichwrap=b,<,>,[,],h,l

