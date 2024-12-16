#!/bin/zsh

# if [[ -d "$(brew --prefix asdf)" ]]; then
#     # We have to source this, because it's implemented as a shell function.
#     source "$(brew --prefix asdf)/libexec/asdf.sh"
# fi

# I've moved from `asdf` to `mise`. They both use the same `.tool-versions` file.
if command -v mise > /dev/null 2>&1; then
    eval "$(mise activate zsh)";
fi
