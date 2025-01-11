#!/bin/zsh

command-exists() {
    type -p "$1" >/dev/null
}

# Use less (instead of more) anywhere paging is required.
export PAGER=less

# When running less, always ignore case on searches, prompt verbosely, display colors, etc.
export LESS='--IGNORE-CASE --LONG-PROMPT --RAW-CONTROL-CHARS --chop-long-lines --tabs=4'

# We should be able to use UTF-8 everywhere these days.
export LESSCHARSET='utf-8'

# Make less more friendly for non-text input files. See lesspipe(1).
if command-exists lesspipe; then
    export LESSPIPE=lesspipe
elif command-exists lesspipe.sh; then
    export LESSPIPE=lesspipe.sh
fi
[[ -n "$LESSPIPE" ]] && eval "$(SHELL=/bin/sh $LESSPIPE)"
