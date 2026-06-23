# Claude Code Hooks

Command hooks invoked by Claude Code (see [`../settings.json`](../settings.json)).

## Task-complete enforcer

[`task-complete-enforcer.ts`](task-complete-enforcer.ts) is a `Stop` hook. When
the assistant emits the `[[task-complete]]` marker in a task that ran
Edits/Writes, it blocks the stop and reminds the assistant to invoke required
skills (e.g. `pre-commit`, `boochtek:documentation`, `retro`) that were missed.

A blocking `Stop` re-invokes the assistant, and the missing-skill condition is
recomputed from the transcript on every `Stop` — so an unconditional block would
fire endlessly until a human intervened. To prevent that, the hook records each
reminder it delivers and suppresses exact repeats.

### Per-session state

- **Location:** `${XDG_CACHE_HOME:-~/.cache}/claude-hooks/task-complete-enforcer/<session_id>.txt`
  (one file per session; `session_id` is sanitized for use as a filename).
- **Contents:** one *fingerprint* per line — the missing-skill names, sorted and
  comma-joined (e.g. `boochtek:documentation,pre-commit`).
- **Behavior:** a fingerprint already present in the file means that exact set of
  missing skills was already flagged this session, so the hook stays silent. A
  *new* set (e.g. after some skills are invoked) blocks once more. Result: at most
  one reminder per session per distinct missing-skill set. The `stop_hook_active`
  early-return remains a second-line backstop, and all filesystem access fails
  open (a write error never suppresses a first reminder).

### Clearing the state

Delete the session's state file (or the whole directory) to make the hook remind
again:

```sh
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/claude-hooks/task-complete-enforcer"
```

### Cross-surface mirrors

The same guard is mirrored, with identical behavior and state path, in the Codex
and OpenCode equivalents:

- [`../../codex/hooks/task-complete-enforcer.ts`](../../codex/hooks/task-complete-enforcer.ts)
  (Codex `Stop` hook)
- [`../../opencode/plugins/enforce-task-complete.ts`](../../opencode/plugins/enforce-task-complete.ts)
  (OpenCode `session.idle` plugin; warns rather than blocks)
