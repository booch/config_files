# See https://zsh.sourceforge.io/Doc/Release/Options.html for full documentation of options.

# ZSH For Humans recommends the following 'setopt' options:
# setopt \
#     'always_to_end'          'auto_cd'                'auto_param_slash'       \
#     'auto_pushd'             'c_bases'                'auto_menu'              \
#     'extended_glob'          'extended_history'       'hist_expire_dups_first' \
#     'hist_find_no_dups'      'hist_ignore_dups'       'hist_ignore_space'      \
#     'hist_verify'            'interactive_comments'   'multios'                \
#     'no_aliases'             'no_bg_nice'             'no_bg_nice'             \
#     'no_flow_control'        'no_prompt_bang'         'no_prompt_subst'        \
#     'prompt_cr'              'prompt_percent'         'prompt_sp'              \
#     'share_history'          'typeset_silent'         'hist_save_no_dups'      \
#     'no_auto_remove_slash'   'no_list_types'          'no_beep'

# setopt typeset_silent pipe_fail extended_glob prompt_percent no_prompt_subst &&
# setopt no_prompt_bang no_bg_nice no_aliases'


## Changing Directories

# Trying to "execute" a directory will change to that directory.
setopt auto_cd

# Don't require an extra TAB press to open the completion menu.
setopt auto_menu

# Make `cd` push the old directory onto the directory stack.
setopt auto_pushd

# Don't print the `cd` stack after `cd` commands.
setopt cd_silent

# Don't beep when trying to complete a non-existent file.
setopt no_beep

# Don't push multiple copies of the same directory onto the directory stack.
setopt pushd_ignore_dups


## Completion

# zmodload -s zsh/terminfo zsh/zselect
# zmodload zsh/{datetime,langinfo,parameter,system,terminfo,zutil}
# zmodload -F zsh/files b:{zf_mkdir,zf_mv,zf_rm,zf_rmdir,zf_ln}
# autoload -Uz $Z4H/zsh4humans/fn/-z4h-gen-init-darwin-paths
# -z4h-gen-init-darwin-paths && source $Z4H/cache/init-darwin-paths
