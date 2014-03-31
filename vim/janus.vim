"
" Custom Janus setup - Craig Buchek
"
" This lets us "call" Janus from our regular .vimrc file.

let g:home_path = expand("~")
let g:vim_path = g:home_path . "/.vim"
let g:janus_path = g:vim_path . "/janus/janus"
let g:janus_vim_path = g:janus_path . "/vim"
let g:janus_custom_path = expand("~/.janus")

if filereadable(g:janus_vim_path)
  exe 'source ' . g:janus_vim_path . '/core/before/plugin/janus.vim'

  " NOTE: these groups will be processed by Pathogen in reverse order.
  call janus#add_group("tools")
  call janus#add_group("langs")
  call janus#add_group("colors")

  " Disable plugins prior to loading pathogen
  exe 'source ' . g:janus_vim_path . '/core/plugins.vim'

  " Load all groups, custom dir, and janus core
  call janus#load_pathogen()
endif
