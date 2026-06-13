# Config Files Repository

This is a public repo. Never commit sensitive information such as credentials,
secret keys, OAuth tokens, API keys, encrypted token caches, or personal
information. Double-check before every commit.

## Directory Structure

- `~/.claude` is a symlink to `~/.config/claude`
- Several files and directories within `~/.config/claude` are symlinks to directories in `~/.config/ai`
  (eg, `~/.config/claude/CLAUDE.md` → `~/.config/ai/AGENTS.md`)
- `.claude/CLAUDE.md` in this repo is a symlink to this file, so Claude Code,
  Codex, and OpenCode all read the same project instructions
- The entire `~/.config` directory is tracked in the `booch/config_files` git repo

## Cross-Surface Parity

This repo configures parallel surfaces that must not drift:

- **Shells** — when changing Bash or Zsh config, check whether the other needs the
  same change. Prefer putting shared logic in `~/.config/sh/*.sh` (sourced by both)
  so it can't diverge. Guard shell-specific syntax: `$BASH_VERSION`/`$ZSH_VERSION`,
  `${HOST:-$HOSTNAME}`, and `[[ "$-" == *i* ]]` over `[[ -o interactive ]]`.
- **AI harnesses** — keep config in sync across Claude Code and OpenCode (primary),
  plus Codex, and leave room for others under trial. Updating agents, skills,
  commands, or hooks for one means mirroring the change to the others, preferably
  via symlinks.
