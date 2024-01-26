#!/bin/bash
#!/bin/zsh
# This file gets sourced by both Bash and Zsh startup scripts.

if [[ -d "$(brew --prefix asdf)" ]]; then
    # We have to source this, because it's implemented as a shell function.
    source "$(brew --prefix asdf)/libexec/asdf.sh"

    # Make sure we get a chance to set the versions for the current directory.
    cd .
fi
