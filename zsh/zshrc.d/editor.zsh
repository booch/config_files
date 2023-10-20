#!/bin/zsh

command-exists() {
    type -p "$1" >/dev/null
}


# Set the default editor to nvim, if it exists. Fall back to vim, nano, or pico.
if command-exists nvim ; then
    export EDITOR=nvim
    alias vi=nvim
    alias vim=nvim
    alias nano=nvim
    alias pico=nvim
elif command-exists vim ; then
    export EDITOR=vim
    alias vi=vim
    alias nvim=vim
    alias nano=vim
    alias pico=vim
elif command-exists nano ; then
    export EDITOR=nano
    alias vi=nano
    alias vim=nano
    alias nvim=nano
    alias pico=nano
elif command-exists pico ; then
    export EDITOR=pico
    alias vi=pico
    alias vim=pico
    alias nvim=pico
    alias nano=pico
fi
