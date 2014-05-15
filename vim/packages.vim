"" Load Vundle
filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Plugin 'gmarik/vundle'


" CtrlP. See docs at http://kien.github.io/ctrlp.vim/.
Plugin 'kien/ctrlp.vim'


" Supertab (make hitting Tab do what I expect)
Plugin 'ervandew/supertab'


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


"" NumberToggle - toggle between absolute and relative line numbers.
Plugin 'jeffkreeftmeijer/vim-numbertoggle'
nnoremap <silent> <leader>tn :call NumberToggle()<cr>


"" Rainbow parentheses - color each matching set of parens differently.
Plugin 'kien/rainbow_parentheses.vim'
" Enable by default.
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces


filetype on

