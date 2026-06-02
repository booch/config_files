#!/usr/bin/exec bash

# Enable fzf keybindings for completions:
#   Ctrl+R = shell command history
#   Ctrl+T = complete from current directory
#   Alt+C = complete only directories from current directory
# Or type `**` in command prompt and hit Tab.
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzfrc"
export FZF_COMPLETION_PATH_OPTS="--preview='less {}'"
export FZF_COMPLETION_DIR_OPTS="--preview='ls -1 {}'"
eval "$(fzf --bash)"
