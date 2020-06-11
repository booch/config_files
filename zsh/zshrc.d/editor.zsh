# Set the default editor to vim, if it exists. Next best choice is nano.
if type -p vim >/dev/null; then
    export EDITOR=vim
    alias nano=vim
    alias pico=vim
elif type -p nano >/dev/null; then
    export EDITOR=nano
    alias pico=nano
elif type -p pico >/dev/null; then
    export EDITOR=pico
    alias nano=pico
fi