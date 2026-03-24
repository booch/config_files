#!/bin/bash

# Morning Briefing Wrapper
# Invoked by launchd at 8:00 AM, or run manually.
# Selects the right AI provider and runs the /morning command.

set -euo pipefail

# Detect machine context.
MORNING_SCRIPT_CONTEXT=$(hostname | cut -d'.' -f1)

# Source config if it exists.
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/morning-briefing"
if [[ -f "$CONFIG_DIR/config.sh" ]]; then
    source "$CONFIG_DIR/config.sh"
fi

# Determine AI provider based on hostname (default to claude).
# Personal Mac: our-flag → claude
# Work Mac: (configure in context.env)
if [[ -z "${MORNING_AI_PROVIDER:-}" ]]; then
    case "$MORNING_SCRIPT_CONTEXT" in
        our-flag*) MORNING_AI_PROVIDER="claude" ;;
        *)         MORNING_AI_PROVIDER="claude" ;;  # Default; override in context.env for work Mac.
    esac
fi

# Ensure output and log directories exist.
OUTPUT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/morning-briefing"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/morning-briefing"
mkdir -p "$OUTPUT_DIR" "$STATE_DIR"

# Log start.
echo "[$(date -Iseconds)] Starting morning briefing (context: $MORNING_SCRIPT_CONTEXT, provider: $MORNING_AI_PROVIDER)" \
    >> "$STATE_DIR/morning-briefing.log"

# Run the appropriate AI command.
case "$MORNING_AI_PROVIDER" in
    claude)
        if command -v claude &> /dev/null; then
            claude /morning 2>> "$STATE_DIR/errors.log"
        else
            echo "[$(date -Iseconds)] ERROR: claude command not found" >> "$STATE_DIR/errors.log"
            exit 1
        fi
        ;;
    openai)
        if command -v codex &> /dev/null; then
            codex /morning 2>> "$STATE_DIR/errors.log"
        else
            echo "[$(date -Iseconds)] ERROR: codex command not found" >> "$STATE_DIR/errors.log"
            exit 1
        fi
        ;;
    *)
        echo "[$(date -Iseconds)] ERROR: Unknown AI provider: $MORNING_AI_PROVIDER" >> "$STATE_DIR/errors.log"
        exit 1
        ;;
esac

# Log completion.
echo "[$(date -Iseconds)] Morning briefing complete" >> "$STATE_DIR/morning-briefing.log"
