"" Load Vundle
filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Plugin 'gmarik/vundle'


" CtrlP. See docs at http://kien.github.io/ctrlp.vim/.
Plugin 'kien/ctrlp.vim'


" Supertab (make hitting Tab do what I expect)
Plugin 'ervandew/supertab'


" Support bracketed paste mode in terminals, so you don't have to manually `:set paste`.
" See https://cirw.in/blog/bracketed-paste for more details.
" NOTE: This currently only works in insert mode.
Plugin 'ConradIrwin/vim-bracketed-paste'


" Grab some color themes.
Plugin 'chriskempson/vim-tomorrow-theme'


"" Airline (nice looking modelines)
Plugin 'vim-airline'

" Make sure the modeline is showing.
set laststatus=2

" Set the theme.
let g:airline_theme='dark'

" Use Unicode symbols to make the modeline look nicer.
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.linenr = ''
let g:airline_symbols.paste = 'PASTE'
let g:airline_symbols.whitespace = 'Ξ'


"" NerdTree - easier file navigation.
Plugin 'scrooloose/nerdtree'


"" Rainbow parentheses - color each matching set of parens differently.
Plugin 'kien/rainbow_parentheses.vim'
" Enable by default.
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces


" Snippet manager and a big pile of "standard" snippets.
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'


"" Fugitive
Plugin 'tpope/vim-git'
Plugin 'tpope/vim-fugitive'


"" Add support for `s` modifier, to select "surrounding" elements.
" See https://github.com/tpope/vim-surround for details.
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-surround'


"" Use Commentary for commenting out code blocks.
" See https://github.com/tpope/vim-commentary for details.
Plugin 'tpope/vim-commentary'


"" Ack
Plugin 'mileszs/ack.vim'


filetype on
