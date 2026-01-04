#!/bin/bash
# Auto-format hook for Claude Code
# Runs after Edit/Write operations to format files
#
# Receives JSON input on stdin with tool_input containing file_path

set -euo pipefail

# Extract file path from JSON input
file_path=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Exit silently if no file path
[[ -z "$file_path" ]] && exit 0

# Exit if file doesn't exist
[[ ! -f "$file_path" ]] && exit 0

# Get file extension
ext="${file_path##*.}"

# Format based on file type
case "$ext" in
    rb)
        # Ruby: use RuboCop auto-correct if available
        if command -v rubocop &>/dev/null; then
            rubocop -a --fail-level=error "$file_path" 2>/dev/null || true
        fi
        ;;
    js|jsx|ts|tsx|mjs|cjs|json)
        # JavaScript/TypeScript: use Prettier if available
        if command -v npx &>/dev/null && [[ -f "package.json" || -f "$(dirname "$file_path")/package.json" ]]; then
            npx prettier --write "$file_path" 2>/dev/null || true
        fi
        ;;
    py|pyi)
        # Python: use Ruff (preferred) or Black
        if command -v ruff &>/dev/null; then
            ruff format "$file_path" 2>/dev/null || true
        elif command -v black &>/dev/null; then
            black --quiet "$file_path" 2>/dev/null || true
        fi
        ;;
    sh|bash|zsh)
        # Shell: use shfmt if available
        if command -v shfmt &>/dev/null; then
            shfmt -w "$file_path" 2>/dev/null || true
        fi
        ;;
esac

exit 0
