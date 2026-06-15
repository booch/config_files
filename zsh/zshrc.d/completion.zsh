#!/bin/zsh

# Enable command completion for everything in Homebrew.
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
fi

# Make tab completion case insensitive. (From https://scriptingosx.com/2019/07/moving-to-zsh-part-5-completions/.)
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# Allow tab completion of multiple partial matches (/u/lo/b -> /usr/local/bin).
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix

# Use a TUI menu for selecting completions.
zstyle ':completion:*' menu select

# Enable tab completion.

# From https://gist.github.com/ctechols/ca1035271ad134841284,
# On slow systems, checking the cached .zcompdump file to see if it must be
# regenerated adds a noticeable delay to Zsh startup.  This little hack restricts
# it to once a day.
#
# The globbing is a little complicated here:
# - '#q' is an explicit glob qualifier that makes globbing work within zsh's [[ ]] construct.
# - 'N' makes the glob pattern evaluate to nothing when it doesn't match (rather than throw a globbing error)
# - '.' matches "regular files"
# - 'mh+24' matches files (or directories or whatever) that are older than 24 hours.
autoload -Uz compinit
# if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
if ! find "${ZDOTDIR:-$HOME}/.zcompdump" -mtime +1 >/dev/null; then
    compinit
else
    compinit -C
fi

# Display red dots whilst waiting for completion.
export COMPLETION_WAITING_DOTS='true'

# Completion of a git branch name should not include remote branches.
export GIT_COMPLETION_CHECKOUT_NO_GUESS=1

# Ignore case when completing git branches.
export GIT_COMPLETION_IGNORE_CASE=1

# Enable automatic suggestions (a la Fish), selected with right arrow.
# TODO: Configure zsh-autosuggestions. See https://github.com/zsh-users/zsh-autosuggestions.
if command -v brew &>/dev/null && [[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Enable command auto-correction.
export ENABLE_CORRECTION="true"

# Enable fzf keybindings for completions:
#   Ctrl+R = shell command history
#   Ctrl+T = complete from current directory
#   Alt+C = complete only directories from current directory
# Or type `**` in command prompt and hit Tab.
export FZF_DEFAULT_OPTS_FILE=~/.config/fzfrc
export FZF_COMPLETION_PATH_OPTS="--preview='less {}'"
export FZF_COMPLETION_DIR_OPTS="--preview='ls -1 {}'"
source <(fzf --zsh)
