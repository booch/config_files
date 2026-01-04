#!/bin/bash
set -euo pipefail

# Color constants (using $'\033' for portability)
readonly COLOR_RESET=$'\033[0m'
readonly COLOR_BLUE=$'\033[1;34m'
readonly COLOR_GREEN=$'\033[1;32m'
readonly COLOR_YELLOW=$'\033[1;33m'
readonly COLOR_RED=$'\033[1;31m'
readonly COLOR_MAGENTA=$'\033[1;35m'

main() {
    local input
    input=$(cat)

    if ! echo "$input" | jq -e . > /dev/null 2>&1; then
        echo "Error: Invalid JSON input" >&2
        return 1
    fi

    local extracted
    extracted=$(echo "$input" | jq -r '[
        .workspace.current_dir // "",
        .model.display_name // "unknown",
        .context_window.context_window_size // 0,
        .cost.total_api_duration_ms // 0,
        .cost.total_cost_usd // 0
    ] | @tsv')

    local cwd model_name context_window api_duration_ms total_cost current_usage
    IFS=$'\t' read -r cwd model_name context_window api_duration_ms total_cost <<< "$extracted"
    current_usage=$(echo "$input" | jq -c '.context_window.current_usage')
    total_cost=$(printf "%.2f" "$total_cost")

    local api_duration cwd_display context_pct context_color git_branch git_display
    api_duration=$(format_duration "$api_duration_ms")
    cwd_display=$(abbreviate_path "$cwd")
    context_pct=$(calculate_context_percentage "$current_usage" "$context_window")
    context_color=$(get_context_color "$context_pct")

    git_branch=$(get_git_branch "$cwd")
    git_display=""
    if [[ -n "$git_branch" ]]; then
        git_display=" (${COLOR_MAGENTA}${git_branch}${COLOR_RESET})"
    fi

    printf "%s%s%s%s | %s%s%s | %s%d%% context%s | %s%s%s | %s\$%s%s" \
        "$COLOR_BLUE" "$cwd_display" "$COLOR_RESET" "$git_display" \
        "$COLOR_RED" "$api_duration" "$COLOR_RESET" \
        "$context_color" "$context_pct" "$COLOR_RESET" \
        "$COLOR_MAGENTA" "$model_name" "$COLOR_RESET" \
        "$COLOR_GREEN" "$total_cost" "$COLOR_RESET"
}

format_duration() {
    local ms=$1
    local seconds=$((ms / 1000))
    local minutes=$((seconds / 60))
    local hours=$((minutes / 60))
    local days=$((hours / 24))

    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ $minutes -lt 60 ]]; then
        local remaining_secs=$((seconds % 60))
        echo "${minutes}m${remaining_secs}s"
    elif [[ $hours -lt 24 ]]; then
        local remaining_mins=$((minutes % 60))
        echo "${hours}h${remaining_mins}m"
    else
        local remaining_hours=$((hours % 24))
        echo "${days}d${remaining_hours}h"
    fi
}

get_context_color() {
    local pct=$1
    if [[ $pct -lt 50 ]]; then
        echo "$COLOR_GREEN"
    elif [[ $pct -lt 80 ]]; then
        echo "$COLOR_YELLOW"
    else
        echo "$COLOR_RED"
    fi
}

calculate_context_percentage() {
    local current_usage=$1
    local context_window=$2

    if [[ "$current_usage" == "null" ]] || [[ -z "$current_usage" ]] || [[ "$context_window" -eq 0 ]]; then
        echo 0
        return
    fi

    local current_total
    current_total=$(echo "$current_usage" | jq -r '(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)')
    echo "$((current_total * 100 / context_window))"
}

get_git_branch() {
    local dir=$1
    if [[ -z "$dir" ]] || [[ ! -d "$dir" ]]; then
        return
    fi
    # Use --no-optional-locks to avoid blocking on git index locks during frequent refreshes
    if [[ -d "$dir/.git" ]] || git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
        git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null || true
    fi
}

abbreviate_path() {
    echo "${1/$HOME/\~}"
}

main "$@"
