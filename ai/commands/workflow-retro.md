---
description: Mine recent session transcripts across AI harnesses for workflow friction, and propose config/skill/hook improvements
allowed-tools: Read, Grep, Glob, Bash, Write, Task
publish: true
---

# Workflow Retrospective (cross-session)

Mine recent session transcripts from all AI harnesses for recurring friction,
then propose concrete improvements. This is `/retro` scaled up: patterns across
sessions, not within one.

## Data Sources

- Claude Code: `~/.claude/projects/*/` (JSONL; skip `memory/` subdirs)
- Codex: `~/.codex/sessions/**/*.jsonl`
- OpenCode: `~/.local/share/opencode/storage/{session,message,part}/`
- Episodic memory archive, if the plugin is available

Focus on sessions since the last workflow retro (check
`~/.local/share/ai/memory/` for a `workflow-retro-last-run` note; if absent,
use the last ~30 days).

## Analysis (delegate each to a subagent; forbid re-delegation in the prompt)

1. **User corrections** — extract user-authored messages only (via `jq`;
   never read raw transcripts into context). Find corrections, repeated
   instructions, and friction. Rank recurring patterns.
2. **Machine-detectable friction** — count hook blocks, permission denials,
   tool errors, plugin errors, API errors. Rank by frequency; identify which
   are self-inflicted (rule violations) vs infrastructure (broken configs).
3. **Cross-harness parity** — compare Claude Code, Codex, and OpenCode
   configs for drift in skills, commands, agents, hooks, and memory wiring.

## Report Format

### 📉 Top Friction Patterns

Ranked; each with frequency, one verbatim example, and root cause.

### 🔧 Proposed Fixes

For each: the fix type (hook / skill / AGENTS.md / memory / config / training),
the specific file, and the change. Prefer fixes that remove whole classes of
friction (e.g. hook auto-rewrite) over documentation that relies on compliance.

### ✅ What's Working

Rules/automations with zero recent violations — evidence they can be trusted.

## Output

1. Display the report.
2. Ask which fixes to apply; make no changes without approval.
3. After approval, record the run date in
   `~/.local/share/ai/memory/workflow-retro-last-run.md` so the next retro
   starts where this one ended.

### `--auto` (headless / scheduled runs)

With `--auto` (e.g. from the monthly launchd job): apply NO fixes and ask
nothing. Write the full report to
`~/.local/share/ai/retro-log/<YYYY-MM>.md`, update
`workflow-retro-last-run.md`, and end with a one-line summary of the top
3 proposed fixes. The user reviews the report file later and applies fixes
in an interactive session.

## Guidelines

- Be token-conscious: delegate extraction to subagents; use `jq`/`grep`
  counting, not full-file reads.
- Weight recent sessions over old ones; note fixes that already landed.
- Distinguish historical noise (already-fixed) from live friction.
