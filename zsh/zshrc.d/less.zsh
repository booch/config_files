#!/bin/zsh

command-exists() {
    type -p "$1" >/dev/null
}

# Use less (instead of more) anywhere paging is required.
export PAGER=less

# When running less, always ignore case on searches; prompt verbosely; display colors;
#  chop long lines; highlight first new line; tabs are 4 chars wide.
export LESS='-I -M -R -S -W -x4'

# We should be able to use UTF-8 everywhere these days.
export LESSCHARSET='utf-8'

# Make less more friendly for non-text input files. See lesspipe(1).
if command-exists lesspipe; then
    export LESSPIPE=lesspipe
elif command-exists lesspipe.sh; then
    export LESSPIPE=lesspipe.sh
fi
[[ -n "$LESSPIPE" ]] && eval "$(SHELL=/bin/sh $LESSPIPE)"
