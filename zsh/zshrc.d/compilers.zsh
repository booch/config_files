#!/bin/zsh

## Mac OS X specific settings.
if [[ "$OSTYPE" = "darwin10.0" ]] ; then
    if [[ "$HOSTTYPE" = "x86_64" ]] ; then
        export ARCHFLAGS="-arch x86_64" # Ensure that mysql gem builds correctly.
    fi
fi
