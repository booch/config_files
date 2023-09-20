# Set the default editor to nvim, if it exists. Fall back to vim, nano, or pico.
if type -p nvim >/dev/null; then
    export EDITOR=nvim
    alias vi=nvim
    alias vim=nvim
    alias nano=nvim
    alias pico=nvim
elif type -p vim >/dev/null; then
    export EDITOR=vim
    alias vi=vim
    alias nvim=vim
    alias nano=vim
    alias pico=vim
elif type -P nano >/dev/null; then
    export EDITOR=nano
    alias vi=nano
    alias vim=nano
    alias nvim=nano
    alias pico=nano
elif type -P pico >/dev/null; then
    export EDITOR=pico
    alias vi=pico
    alias vim=pico
    alias nvim=pico
    alias nano=pico
fi
