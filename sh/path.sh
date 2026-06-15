# ~/.config/sh/path.sh — shared PATH setup for bash and zsh.
#
# Problem this solves: shells spawned non-interactively (e.g. `zsh -c …` or
# `bash -c …`, as editors, cron, and tool harnesses do) never source .zshrc or
# an interactive .bashrc, so the tool setup that lives there is skipped and the
# shell falls back to a bare system PATH — wrong Ruby, no mise, no Homebrew.
# This file is the single place that guarantees the right tools are on PATH,
# and it is wired into every startup path that DOES run (see callers below).
#
# Sourced by:
#   - zsh: ~/.zshenv (every invocation) and ~/.zprofile (after path_helper)
#   - bash: $BASH_ENV (non-interactive `bash -c`); login is covered below
#   - both: the shared ~/.config/sh/*.sh loop in zshrc/bash_profile, which
#     re-sources this file harmlessly (it is idempotent)
#
# Keep it fast, silent, and idempotent: it runs for every shell. Uses only
# bash/zsh parameter expansion (not pure POSIX), which is fine for its callers.

# Prepend $1 to PATH, moving it to the front if already present (so re-sourcing
# after macOS path_helper restores precedence). Skips non-existent directories.
_prepend_path() {
    [ -d "$1" ] || return
    PATH=":$PATH:"
    PATH="${PATH//:$1:/:}"
    PATH="${PATH#:}"
    PATH="${PATH%:}"
    PATH="$1:$PATH"
}

# Lowest precedence first; each prepend moves its entry to the front, so the
# final order (front to back) is the reverse of this list.
_prepend_path "$HOME/.antigravity/antigravity/bin"   # Antigravity editor CLI (agy, antigravity)
_prepend_path "/opt/homebrew/sbin"
_prepend_path "/opt/homebrew/bin"
_prepend_path "$HOME/.local/share/mise/shims"   # all mise-managed tools, no activation hook
_prepend_path "$HOME/.local/bin"
_prepend_path "$HOME/bin"
export PATH
unset -f _prepend_path

# Make non-interactive bash (`bash -c …`) source this file at startup. Exporting
# it here means any shell that sources this propagates it to bash children.
export BASH_ENV="$HOME/.config/sh/path.sh"
