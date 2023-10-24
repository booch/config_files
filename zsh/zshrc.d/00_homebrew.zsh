#!/bin/zsh

# Determine if we're on Apple Silicon or Intel. Homebrew gets installed different places for each.
if [[ $(arch) == 'i386' ]]; then
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
