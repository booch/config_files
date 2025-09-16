#!/bin/bash

# Specify gems to install with every version of Ruby.
export MISE_RUBY_DEFAULT_PACKAGES_FILE="$HOME/.config/ruby/default-gems"

# Activate Mise - adds a shell function (so `mise shell` works) and a precmd function (to change $PATH).
if command -v mise &> /dev/null; then
    eval "$(mise activate)" &> /dev/null

    # Load Mise completions.
    eval "$(mise completion $(basename $SHELL))" &> /dev/null
fi
