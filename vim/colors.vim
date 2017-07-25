" Only use color if the terminal can handle it.
if (&t_Co > 2)

  " Force a light background. (Antique white where possible, white otherwise.)
  if (&t_Co > 16)
    highlight Normal ctermfg=black ctermbg=231 guifg=black guibg=#FAEBD7
  else
    highlight Normal ctermfg=black ctermbg=white
  endif

  " Set the color scheme.
  " NOTE: We can't seem to override anything in the color scheme before OR after it's loaded.
  " Acceptable light color schemes:
  "     intellij
  "     LuciusLight
  " Acceptable dark color schemes:
  "     CodeSchool - http://astonj.com/tech/vim-for-ruby-rails-and-a-sexy-theme/
  try
    colorscheme Tomorrow
  catch /^Vim\%((\a\+)\)\=:E185/
    " Use default colorscheme for now.
  endtry

  if has('syntax')
    syntax on

    " Don't try to highlight long lines.
    set synmaxcol=256
  endif

  " Highlight the current line with a light grey background, only for the current buffer.
  " Change the current line background to white when in INSERT mode.
  set cursorline
  augroup cline
    au!
    au WinLeave * setlocal nocursorline
    au VimEnter,WinEnter,BufWinEnter,InsertLeave * highlight cursorline term=none cterm=none ctermbg=white gui=none guibg=white
    au VimEnter,WinEnter,BufWinEnter,InsertLeave * setlocal cursorline
    au InsertEnter * highlight cursorline term=none cterm=none ctermbg=lightgrey gui=none guibg=lightgrey
    au InsertEnter * setlocal cursorline
  augroup END

  " Highlight the current line more clearly in insert mode. (Match Airline colors.)
  au InsertEnter * highlight cursorline term=none cterm=none ctermbg=45 gui=none guibg=#00DFFF
  au InsertLeave * highlight cursorline term=none cterm=none ctermbg=lightgrey gui=none guibg=lightgrey

  " Show indicators for columns 80 and 120.
  set colorcolumn=80,120
  highlight ColorColumn ctermbg=white guibg=white

endif
