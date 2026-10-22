# Functions for finding processes.
# This file gets sourced by both Bash and Zsh startup scripts.

# `pidof NAME...`: the IDs of processes with exactly that name, on one line.
# Exits 1 if there are none. (Replaces the pidof formula that Homebrew dropped.)
pidof() {
    local pids
    pids="$(for name in "$@"; do pgrep -x -- "$name"; done | paste -sd ' ' -)"
    [ -n "$pids" ] && echo "$pids"
}
