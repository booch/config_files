---
name: bash-tool
description: Rules for using the Bash tool in Claude Code. This skill should be used when running shell commands via the Bash tool, especially for multi-command tasks, brew updates, build scripts, or any session involving significant shell usage. Use proactively before running Bash commands.
publish: true
---

# Bash Tool Usage

Rules for using the Bash tool correctly within AI agents.
NOTE: This was written for and tested with Claude Code; other agents may need to adapt.

## Critical Rules

### Never use stderr redirections

Never append `2>&1`, `2>/dev/null`, `2>file`, or ANY `2>` redirect to Bash tool commands.

- The Bash tool already captures both stdout and stderr — redirections are unnecessary
- Adding redirections breaks exact-match permission rules (e.g., `brew upgrade` is allowed but `brew upgrade 2>/dev/null` is not)
- This causes `PreToolUse:Bash hook error` and forces a retry
- Suppressing stderr hides information the agent should read and interpret

**What to do instead:** Run commands plainly. If they produce errors, read the error and respond to it. "Handle gracefully" means reading and explaining the error, not hiding it.

```bash
# WRONG — suppresses useful error info, breaks permissions
python3 --version 2>/dev/null
ls /tmp/maybe 2>/dev/null
brew update 2>&1

# RIGHT — run plainly, read the result, respond intelligently
python3 --version
ls /tmp/maybe
brew update
```

### Red Flags — You Are About to Violate This Rule

If you're thinking any of these, STOP:

| Thought | Reality |
|---------|---------|
| "I want clean output" | The Bash tool separates stdout/stderr for you already |
| "Suppress errors silently" | Errors are information. Read them, don't hide them. |
| "Handle gracefully = no errors" | Handle gracefully = read error, explain what happened |
| "`2>/dev/null` isn't `2>&1`" | ALL stderr redirections are prohibited, not just `2>&1` |
| "User won't want to see errors" | You filter what to show the user in your response, not in the shell |
| "The command might fail" | Let it fail. Read the error. Respond accordingly. |

### Prefer dedicated tools over shell equivalents

Do not use the Bash tool when a dedicated tool exists:

| Instead of | Use |
|------------|-----|
| `cat`, `head`, `tail` | **Read** tool |
| `grep`, `rg` | **Grep** tool |
| `find`, `ls` (for search) | **Glob** tool |
| `sed`, `awk` (for edits) | **Edit** tool |
| `echo >`, `cat <<EOF >` | **Write** tool |

**Exception:** Shell equivalents are fine when they are part of a pipeline (e.g., `command | grep pattern | head -5`).

### Use `git -C` instead of `cd` for subdirectory git operations

When running git commands in a subdirectory (submodules, worktrees, etc.), use `git -C <path>` instead of `cd <path> && git ...`. Changing directories with `cd` persists across Bash tool calls and causes confusion in subsequent commands.

```bash
# WRONG — changes working directory for all future commands
cd claude/plugins/marketplaces/boochtek && git status

# RIGHT — working directory stays unchanged
git -C claude/plugins/marketplaces/boochtek status
```

### Use `jq` and `yq` for data processing

Use `jq` for JSON and `yq` for YAML instead of writing one-off Python scripts.

```bash
# WRONG — unnecessary Python script for simple JSON extraction
python3 -c "import json; print(json.load(open('config.json'))['version'])"

# RIGHT — jq is simpler and more composable
jq '.version' config.json

# WRONG — Python for YAML manipulation
python3 -c "import yaml; d=yaml.safe_load(open('config.yaml')); print(d['name'])"

# RIGHT — yq handles YAML natively
yq '.name' config.yaml
```

Only fall back to Python when the transformation is too complex for `jq`/`yq` (e.g., multi-file joins with complex logic, or when a Python script already exists for the task).

### Permission-aware command construction

Bash permissions use exact-match patterns. When constructing commands:

- Keep commands simple and matching established patterns
- Do not add unnecessary flags, pipes, or redirections that would change the match
- If a command is allowed as `Bash(brew upgrade)`, run exactly `brew upgrade`

## Shell Compatibility: Zsh vs Bash

The Bash tool runs commands through the user's configured shell, which may be
**Zsh or Bash** (the tool is named "Bash" but does not guarantee Bash). Check with
`echo "$ZSH_VERSION"` / `echo "$BASH_VERSION"` when in doubt. Don't assume Bash-only
semantics — prefer constructs that work the same in both shells, and watch for
the Zsh differences below.

### Unquoted variables do NOT word-split in Zsh

In Bash, an unquoted `$var` splits on `$IFS`. In Zsh, it does **not** — the whole
value stays one word. A loop over a space-joined scalar then runs once with the
entire string instead of once per item, usually surfacing as a "No such file or
directory" error containing every item at once.

```bash
# FRAGILE — works in Bash, breaks in Zsh (one iteration, whole string as $f)
files="a.sh b.sh c.sh"
for f in $files; do shellcheck "$f"; done

# PORTABLE — list items inline; identical behavior in both shells
for f in a.sh b.sh c.sh; do shellcheck "$f"; done

# PORTABLE — use a real array; `( )` and "${arr[@]}" work in both Bash and Zsh
files=(a.sh b.sh c.sh)
for f in "${files[@]}"; do shellcheck "$f"; done
```

Avoid the Zsh-only `${=files}` force-split — it errors in Bash. Use a literal
list or array instead, so the command works regardless of which shell runs it.
