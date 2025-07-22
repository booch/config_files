#!/bin/zsh

if command -v brew &> /dev/null && [[ -r "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Automatically match pairs of quotes, parentheses, brackets, etc.
# NOTE: This has to be sourced after `bindkey -e` (in `key_bindings`).
if command -v brew &> /dev/null && [[ -f "$(brew --prefix)/share/zsh-autopair/autopair.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-autopair/autopair.zsh"
fi
