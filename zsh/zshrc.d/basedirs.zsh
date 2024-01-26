#!/bin/bash
#!/bin/zsh
# This file gets sourced by both Bash and Zsh startup scripts.

# Define variables for programs conforming to the
# [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec).

# Define the variables.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
if [[ "$(uname)" == 'Darwin' ]]; then
    export XDG_CACHE_HOME="$HOME/Library/Caches"
else
    export XDG_CACHE_HOME="$HOME/.cache"
fi
# NOTE: We might change this to `/var/run/user/$USER` on Mac, because `var/run` is owned by root, and not 700.
export XDG_RUNTIME_DIR='/var/run'

# Make sure the directories exist, and are private.
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
chmod 700 "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

# TODO: Only include directories that exist.
export XDG_CONFIG_DIRS="$HOMEBREW_PREFIX/etc:/user/local/etc:/etc/xdg:/etc"
export XDG_DATA_DIRS="$HOMEBREW_PREFIX/share:/usr/local/share:/usr/share"
