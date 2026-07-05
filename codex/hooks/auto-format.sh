#!/bin/bash
# Auto-format hook for Codex CLI
# Runs after apply_patch operations to format changed files
#
# Receives JSON input on stdin. Codex's apply_patch tool does not report a
# simple file_path like Claude Code's Edit/Write — it reports:
#   - tool_response.files_modified: an array of changed paths (preferred), or
#   - tool_input.command: the raw patch text, with paths on
#     "*** Update File: <path>" / "*** Add File: <path>" marker lines (fallback).

set -euo pipefail

input=$(cat)

# Preferred: tool_response.files_modified array.
mapfile -t file_paths < <(echo "$input" | jq -r '.tool_response.files_modified // [] | .[]')

# Fallback: parse patch marker lines out of tool_input.command.
if [[ ${#file_paths[@]} -eq 0 ]]; then
    mapfile -t file_paths < <(
        echo "$input" | jq -r '.tool_input.command // empty' |
            grep -E '^\*\*\* (Update|Add) File:' |
            sed 's/^\*\*\* [^ ]* File: //'
    )
fi

# Exit silently if no files found
[[ ${#file_paths[@]} -eq 0 ]] && exit 0

format_one() {
    local file_path="$1"

    # Exit if file doesn't exist
    [[ ! -f "$file_path" ]] && return 0

    # Get file extension
    local ext="${file_path##*.}"

    # Format based on file type
    case "$ext" in
    rb)
        # Ruby: use RuboCop auto-correct if available
        if command -v rubocop &>/dev/null; then
            rubocop -a --fail-level=error "$file_path" || true
        fi
        ;;
    js | jsx | ts | tsx | mjs | cjs | json)
        # JavaScript/TypeScript: use Prettier if available
        if command -v npx &>/dev/null && [[ -f "package.json" || -f "$(dirname "$file_path")/package.json" ]]; then
            npx prettier --write "$file_path" || true
        fi
        ;;
    py | pyi)
        # Python: use Ruff (preferred) or Black
        if command -v ruff &>/dev/null; then
            ruff format "$file_path" || true
        elif command -v black &>/dev/null; then
            black --quiet "$file_path" || true
        fi
        ;;
    sh | bash | zsh)
        # Shell: use shfmt if available
        if command -v shfmt &>/dev/null; then
            shfmt -w "$file_path" || true
        fi
        ;;
    esac
}

for file_path in "${file_paths[@]}"; do
    format_one "$file_path"
done

exit 0
