#!/bin/bash
#!/bin/zsh
# This file gets sourced by both Bash and Zsh startup scripts.

# Define variables for programs conforming to the
# [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec).
# These are mostly the defaults, but I want to be explicit.

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
#       We'd need to have root create the containing directory, and set permissions appropriately.
export XDG_RUNTIME_DIR='/var/run'

# Make sure the directories exist, and are private.
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
chmod 700 "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

# Additional directories to look for CONFIG and DATA files, in addition to the XDG_*_HOME directories.
for dir in "/usr/local/etc" "$HOMEBREW_PREFIX/etc" "/etc/xdg" "/etc"; do
    if [[ -d "$dir" ]]; then
        export XDG_CONFIG_DIRS="$dir:$XDG_CONFIG_DIRS"
    fi
done
for dir in "/usr/local/share" "$HOMEBREW_PREFIX/share" "/usr/share"; do
    if [[ -d "$dir" ]]; then
        export XDG_DATA_DIRS="$dir:$XDG_DATA_DIRS"
    fi
done

# NOTE: I don't know how to handle `XDG_RUNTIME_DIR`.
#       It should be created by the login manager, and deleted when the user logs out, or on boot.
#       It's supposed to be only accessible by the user.
