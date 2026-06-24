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

## Pre-commit gates

Two `PreToolUse` hooks matched on `Bash`. Each acts only when the command runs a
`git commit`, detected by [`isGitCommit`](lib/git.ts), which splits the command
on newlines as well as `;`/`&&`/`||`/`|` — so a commit in a multi-line block is
still caught. (Missing that was a real bug: the gates never fired.) Both fail
open: any error lets the commit proceed.

### Documentation check

[`pre-commit-doc-check.ts`](pre-commit-doc-check.ts) blocks a commit when the
current task ran Edits/Writes to non-doc files but never invoked the
`documentation` skill. Mirror:
[`../../codex/hooks/pre-commit-doc-check.ts`](../../codex/hooks/pre-commit-doc-check.ts).

### Lint-regression gate

[`pre-commit-lint-check.ts`](pre-commit-lint-check.ts) blocks a commit when a
staged file has **more** lint issues than the same file at `HEAD` — a
*regression*. Pre-existing lint debt never blocks; only net-new issues do, so the
gate is safe to run over a repo that already carries debt.

- **Counts** come from a registry ([`lib/lint-registry.ts`](lib/lint-registry.ts)):
  shellcheck + shfmt (shell), markdownlint (Markdown), ruff (Python), and rubocop
  (Ruby, via `bundle exec` when a `Gemfile` is present).
- **New files** (no `HEAD` baseline) are gated only by config-respecting linters.
  Markdown new files are skipped on purpose — the house style legitimately
  diverges from the configured rules, so a fresh `.md` is never blocked on style.
- **Fail-open:** a missing tool, timeout, unparseable output, or non-repo yields
  no count and never blocks. Ruby/Python are best-effort and inert until a usable
  linter is on `PATH`.
- **Performance:** a clean staged file (count 0) skips the `HEAD` baseline run.
- **Extending:** add a `Linter` to the registry and map its extensions in
  `lintersFor`. A linter MUST return `null` (never a guessed number) whenever it
  cannot produce a reliable count.

## Shared library (`lib/`)

- [`lib/git.ts`](lib/git.ts) — `isGitCommit` (the single source of commit
  detection, shared by both pre-commit hooks) plus git helpers: repo root, staged
  files, and `HEAD` content.
- [`lib/lint-registry.ts`](lib/lint-registry.ts) — per-language linters for the
  lint-regression gate.
- [`lib/task-scope.ts`](lib/task-scope.ts) — transcript analysis (completion
  marker, files modified, skills invoked) used by the enforcer and doc-check.

## Activation

Hooks load at session start, so changes to `settings.json` registration require
restarting Claude Code. Hook *script* contents are re-read on each invocation, so
edits to the `.ts` files themselves take effect immediately.
