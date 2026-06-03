#!/bin/bash
#!/bin/zsh
# This file gets sourced by both Bash and Zsh startup scripts.

# Define variables for programs conforming to the
# [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec).
# These are mostly the defaults, but I want to be explicit.
# TODO: Add non-standardized items like $XDG_MUSIC_DIR, DESKTOP, DOCUMENTS, DOWNLOAD, etc from https://gist.github.com/roalcantara/107ba66dfa3b9d023ac9329e639bc58c

# Define the variables.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export CODEX_HOME="$XDG_CONFIG_HOME/codex"
if [[ "$(uname)" == 'Darwin' ]]; then
    export XDG_CACHE_HOME="$HOME/Library/Caches"
    # On Mac, `/var/run` is owned by root.
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/${USER}/run}"
else
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_RUNTIME_DIR='/var/run'
fi

# NOTE: This isn't in the XDG spec, but Systemd uses it.
export XDG_BIN_HOME="$HOME/.local/bin"

# Make sure the directories exist, and are private.
for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME" "$XDG_RUNTIME_DIR"; do
    mkdir -p "$dir"
    chmod 700 "$dir"
done

# Bun: route global packages, bin, and cache to XDG dirs.
# Env vars (not bunfig) because bunfig doesn't expand ${VAR} in install paths.
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export BUN_INSTALL_BIN="$XDG_BIN_HOME"
export BUN_INSTALL_CACHE_DIR="$XDG_CACHE_HOME/bun"

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
