#!/bin/bash
#!/bin/zsh
# This file gets sourced by both Bash and Zsh startup scripts.

# AI tools configuration.

# OpenCode: load agents/commands/skills from the shared ~/.config/ai/ directory.
export OPENCODE_CONFIG_DIR="$HOME/.config/ai"

# Chief of Staff: the manager session that tracks and spawns worker sessions.
alias cos='claude --agent chief-of-staff'
