# Config Files Repository

This is a public repo. Never commit sensitive information such as credentials,
secret keys, OAuth tokens, API keys, encrypted token caches, or personal
information. Double-check before every commit.

## Directory Structure

- `~/.claude` is a symlink to `~/.config/claude`
- Several files and directories within `~/.config/claude` are symlinks to directories in `~/.config/ai`
  (eg, `~/.config/claude/CLAUDE.md` → `~/.config/ai/AGENTS.md`)
- The entire `~/.config` directory is tracked in the `booch/config_files` git repo
