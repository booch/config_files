#!/bin/bash
#!/bin/zsh
# This file gets sourced by both Bash and Zsh startup scripts.

# We only use Homebrew on macOS.
if [[ "$(uname)" != 'Darwin' ]]; then
    return
fi

# Determine if we're on Apple Silicon or Intel. Homebrew gets installed different places for each.
if [[ "$(arch)" == 'i386' ]]; then
    export HOMEBREW_ARCH='x86_64'
    export HOMEBREW_PREFIX='/usr/local'
else
    export HOMEBREW_ARCH='arm64e'
    export HOMEBREW_PREFIX='/opt/homebrew'
fi
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"

# Don't automatically clean up after installs. (Allows easier switching to older versions.)
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Don't automatically update; we'll do that manually.
export HOMEBREW_NO_AUTO_UPDATE=1

# Don't upgrade dependencies when we're trying to install packages.
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
if [[ -e $HOMEBREW_PREFIX/Homebrew/Library ]]; then
    export HOMEBREW_REPOSITORY=$HOMEBREW_PREFIX/Homebrew
else
    export HOMEBREW_REPOSITORY=$HOMEBREW_PREFIX
fi

# Disable quarantine ("Are you sure you want to open this?" prompt) when installing Casks.
export HOMEBREW_CASK_OPTS='--no-quarantine'

# TODO: Add to manpath and infopath.
