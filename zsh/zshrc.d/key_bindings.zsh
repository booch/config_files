#!/bin/zsh

# Use Emacs-style keybindings.
bindkey -e

# These *had* been working in iTerm2, but then seemed to have stopped working.
bindkey '\e[1~' beginning-of-line # Home
bindkey '\e[OH' beginning-of-line # Home
bindkey '\eOH' beginning-of-line
bindkey '\e[H' beginning-of-line
bindkey '\e[4~' end-of-line # End
bindkey '\e[OF' end-of-line # End
bindkey '\eOF' end-of-line
bindkey '\e[F' end-of-line

bindkey '\e[1;5C' forward-word
bindkey '\e[5C' forward-word
bindkey '\e\e[C' forward-word
bindkey '\e[1;5D' backward-word
bindkey '\e[5D' backward-word
bindkey '\e\e[D' backward-word

# Idea from https://github.com/eevee/rc/blob/master/.zshrc
up-line-or-local-search() {
    zle set-local-history 1
    zle up-line-or-search
    zle set-local-history 0
}
zle -N up-line-or-local-search
down-line-or-local-search() {
    zle set-local-history 1
    zle down-line-or-search
    zle set-local-history 0
}
zle -N down-line-or-local-search
bindkey '\e[A' up-line-or-local-search   # Up
bindkey '\eOA' up-line-or-local-search   # Up
bindkey '\e[B' down-line-or-local-search # Down
bindkey '\eOB' down-line-or-local-search # Down

bindkey '^i' complete-word           # Tab to do menu
bindkey '\e[Z' reverse-menu-complete # Shift+Tab to reverse menu

# Ignore a single quote if it's the last character before hitting ENTER (and unmatched). (Because I hit it by accident sometimes.)
export KEYBOARD_HACK="'"
