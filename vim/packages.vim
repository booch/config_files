"" Load Vundle
filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Plugin 'gmarik/vundle'


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


filetype on

