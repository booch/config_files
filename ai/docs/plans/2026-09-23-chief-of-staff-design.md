# Design: Chief of Staff Agent

**Date:** 2026-09-23
**Status:** Approved; ready for implementation planning.
**Approach:** A persona agent for judgment, backed by a small `chief` CLI for
mechanics, with harness-neutral state in plain files.

## Overview

The Chief of Staff ("Chief") is the default entry point for AI sessions. It is a
manager, not a worker: it shows work in progress, makes suggestions, spawns full
sessions for other agents to do the actual work, and tracks those sessions across
time and across harnesses.

Chief runs in Claude Code initially, but nothing about its state or its workers is
Claude-specific. It spawns Claude Code, Codex, and OpenCode sessions, choosing
harness, model, and effort from capability and cost.

## Goals

- A new session starts with Chief, showing in-flight work and suggesting next steps.
- Chief spawns full, resumable sessions — not subagents — so they can be entered
  from a terminal, the Claude desktop app, or Zed.
- Cross-session memory that survives `/clear`, a new harness, or a week away.
- Workers run autonomously by default; Chief inserts checkpoints when warranted.
- Unreviewed output from daily scheduled tasks (Homebrew) surfaces at session start.

## Non-Goals

- Email, calendar, and news briefing. The `/morning` command covers that; Chief may
  offer to run it, but does not absorb it.
- A hosted or daemonized orchestrator. Chief is an ordinary session, not a service.
- Simultaneous multi-model collaboration in round one. See
  [Cross-checking](#cross-checking-on-difficult-tasks).

## Architecture

Four pieces, each with one job.

### 1. The `chief` CLI

Location: `~/.config/ai/tools/chief-of-staff/`. Bun + TypeScript, matching the
existing `md2html` tool and the Codex hooks. Executable name: `chief`.

Owns everything mechanical and deterministic:

- `chief spawn` — mint a session id, choose harness/model/effort, create the
  worktree, launch the session, record it
- `chief list` / `chief status <id>` — registry state, liveness, last activity
- `chief digest <id>` — summarize a worker's recent transcript; all harness-specific
  transcript parsing lives here
- `chief report <id>` — called *by workers* (from a Stop hook) to report state
- `chief note` / `chief close` — journal and registry writes
- `chief models` — probe and cache the available model roster
- `chief updates` — unreviewed scheduled-task output (Homebrew and friends); mark reviewed
- `chief briefing` — one JSON blob with everything a session start needs, so Chief
  makes one call rather than ten

### 2. The Chief agent definition

Location: `~/.config/ai/agents/chief-of-staff/AGENT.md`, symlinked into each
harness per the repo's cross-surface parity rule.

Pure judgment, no mechanics: how to open a session, when to insert a checkpoint
versus run autonomously, the approval tiers, how to choose harness and model, tone.
It calls the CLI and interprets results.

### 3. State

Location: `~/.local/share/ai/chief-of-staff/`. Plain files, harness-neutral.

- `registry.json` — one record per spawned session
- `journal/YYYY-MM.md` — append-only log of decisions, escalations, and responses
- `config.toml` — the only hand-edited file: `[models]` tags that probing cannot
  discover, and `[watch]` listing scheduled-task output directories
- `reviewed.json` — the watermark of which scheduled-task output has been seen

Scheduled tasks write their own output, each to its own directory — for example
`~/.local/share/ai/mac-software-updates/YYYY-MM-DD.md`. Chief reads those
directories; it does not own them, and a task's output remains useful on its own
if Chief is not running.

### 4. Surface adapters

Thin, optional, added last. The CLI must never require a harness-specific surface
to function; adapters only make jumping into a session nicer.

- Terminal: `chief attach <id>` shells out to `claude attach`, `codex resume`, or
  `opencode run --session`
- Desktop app: when Chief runs in the app, it also uses the `ccd_sidebar` and
  `ccd_window` tools to group and open sessions
- Zed: a wrapper that opens the worktree in Zed and resumes the thread

## Data Model

### Registry record

```json
{
  "id": "5f3a…",
  "slug": "chief-cli",
  "goal": "Implement chief spawn + registry",
  "harness": "claude",
  "model": "opus",
  "effort": "high",
  "repo": "~/.config",
  "worktree": "~/.local/share/claude/worktrees/.config/chief-cli",
  "branch": "chief-cli",
  "autonomy": "auto",
  "state": "running",
  "waiting_on": null,
  "cross_check": null,
  "spawned_at": "2026-09-23T14:02:00Z",
  "last_activity_at": "2026-09-23T14:40:00Z",
  "attach": {
    "terminal": "claude attach 5f3a…",
    "resume": "claude --resume 5f3a…"
  }
}
```

Field notes:

- `harness` is one of `claude`, `codex`, `opencode`.
- `autonomy` is `auto` or `checkpointed`.
- `state` is `running`, `waiting`, `blocked`, `done`, or `abandoned`.
- `waiting_on` names the checkpoint when `state` is `waiting` (e.g. `approve-tests`).
- `cross_check` holds the paired reviewer session id, when one exists.

`registry.json` is the only mutable shared file. The CLI writes it atomically
(temp file plus rename) so two Chiefs on different surfaces cannot corrupt it.

### Journal

Append-only, human-readable, the cross-session memory:

```markdown
## 2026-09-23

- 14:02 spawned `chief-cli` (claude/opus/high, auto) — goal: implement spawn + registry
- 14:40 `chief-cli` waiting: tests written, needs your review → escalated (tier: spec design)
- 15:05 approved; released to implement
```

Chief reads the tail of this at session start.

## Spawn Flow

`chief spawn --goal "…" [--repo] [--harness] [--model] [--effort] [--autonomy]`:

1. Resolve the repo; create the worktree and branch, following the conventions in
   the `superpowers:using-git-worktrees` skill.
2. Mint a UUIDv7. Version 7 sorts by creation time, so the registry and any
   id-named files fall into chronological order without a separate sort key;
   `claude --session-id` accepts it, since v7 is a well-formed UUID.
   Write the kickoff prompt to `<worktree>/.chief-kickoff.md` — goal,
   constraints, autonomy mode, and the instruction to report status by running
   `chief report <id>`.
3. Launch, per harness:
    - `claude --bg --session-id <uuid> --name <slug> --model … --effort … --permission-mode auto --settings <chief-hooks.json>`
    - `codex exec` in the background, capturing the id Codex mints
    - `opencode run --title <slug> --model … --agent …` in the background
4. Append the record; print it along with the attach commands.

### How Chief learns a worker's state

Two mechanisms, in priority order.

**Push (preferred).** Spawned workers get a Stop hook — `--settings` for Claude,
`codex_hooks` for Codex — that calls `chief report <id> --state waiting|done
--summary "…"`. The worker tells us; no polling. This mirrors the Stop hooks
already in use in this config.

**Pull (fallback).** `chief digest <id>` reads the transcript
(`~/.claude/projects/<slug>/<uuid>.jsonl`, `~/.codex/sessions/…`, or
`opencode export`) and derives last activity plus a summary. Used when a hook did
not fire, or when detail is wanted.

## Session Start

Chief runs `chief briefing` and renders three zones, sized to fit a screen:

```text
3 sessions in flight

  ⏸  chief-cli      waiting on you — tests written, needs review     (2h)
  ▶  blog-hugo      running — drafting post 3 of 4                   (20m)
  ⚠  mac-setup      stalled 3d — last activity: failing brew test

Since you were last here
  • Homebrew 09/22 — 14 upgrades, jj 0.32→0.33 (breaking: `jj log -r` syntax)
  • Homebrew 09/21 — 6 upgrades, nothing notable
  • workflow-retro ran 09/21 — 3 friction items

Suggestions
  1. chief-cli's tests are blocking two other things — review first?
  2. No blog post since 09/04; blog-hugo has a draft ready.
```

Suggestions must be justified by something in the first two zones. Generic advice
is not a suggestion.

Scope of what Chief tracks: coding work, plus the project list in
`~/Personal/Projects/Current.md` and the goals in `~/.config/ai/HUMAN.md`.

## Autonomy and Approval

Workers run autonomously (`auto`) by default. Chief decides autonomy per spawn, at
spawn time, and states which it chose and why.

| Chief handles silently | Chief escalates, always | Chief's judgment |
| --- | --- | --- |
| Tool permissions, lint fixes, green-keeping refactors, commit messages, review-round fixes | Test and spec design for non-trivial work, push and PR, destructive operations, mid-task scope changes | Everything else |

Two rules attach to that table:

- When Chief makes a judgment call **not** to escalate, it records one line in the
  journal saying why. That log is how the tiers get tuned, and it keeps the
  decisions reviewable rather than opaque.
- The escalation inbox is not a separate queue. It is registry records with
  `state: waiting`. Approving one writes the approval into the worker's session and
  flips the state back to `running`.

## Model Selection

### The roster is discovered, not configured

`chief models` probes what is actually available and caches the result:

- Local engines: a per-engine probe command (`ollama list` today; LM Studio, MLX,
  and llama.cpp are entries of the same shape)
- `claude` model aliases, `codex` profiles, OpenCode providers

An engine entry is `{ name, probe-command, list-parser, opencode-provider }`, so
changing engines is a config edit rather than a code change.

The `[models]` section of `config.toml` holds only what probing cannot tell us:
per-model tags such as
`tier` (`frontier`, `mid`, `local`), `good-at` (`architecture`, `bulk`, `review`),
and supported effort levels. A new model is tagged once; nothing else changes.

This matters because the roster drifts. As of this writing `opencode.jsonc` lists
qwen3-coder, devstral, gemma4:31b, and glm-4.7-flash, while `ollama list` actually
has `ornith-1.5:35b` and a modified `gemma-4-12B-coder` GGUF. Nothing in Chief may
hardcode a model list.

### Default policy

| Work | Choice |
| --- | --- |
| Difficult — architecture, long-horizon, nasty debugging | Fable `xhigh` and Astra `xhigh` (Codex), cross-checking |
| Default coding | Claude Code, `opus`, effort `high` |
| Mechanical or bulk | OpenCode with a local model (Ornith 1.5 today; Qwen when installed) |
| Low on Claude quota | Codex with Sol, its default |
| Second opinion, or a stuck worker | Codex with Sol |

Tier equivalence across harnesses, from the top down:

| Tier | Claude | Codex |
| --- | --- | --- |
| Difficult | Fable | Astra |
| Default | Opus | Sol (Codex's default and primary) |
| Mid | Sonnet | Terra |

So "route this to Codex" means Sol, dropping to Terra for mid-tier work and rising
to Astra only in the difficult tier.

Two baked-in rules:

- Start one tier down for mechanical work and escalate on failure.
- Never silently downgrade a task already declared Opus-worthy. If Chief changes
  its mind mid-task, it says so.

### Quota awareness

`~/.claude/abtop-rate-limits.json` carries `five_hour.used_percentage`,
`seven_day.used_percentage`, and reset timestamps, written by the abtop statusline
hook. Chief reads it at spawn time to decide when to route work to Codex.

### Cross-checking on difficult tasks

Round one is **sequential cross-check**, which works reliably with the primitives
that exist today:

1. The primary model (Fable) does the work.
2. On completion, Chief spawns a reviewer session on the other model (Astra via
   Codex), pointed at the diff with a specific prompt.
3. Disagreements escalate with both positions stated.
4. Optionally one further exchange where each responds to the other's critique,
   capped at one round.

Simultaneous collaboration needs a relay loop between two live sessions. That is a
follow-on, not part of this design.

## Scheduled Task Reports

Chief shows unreviewed output from daily scheduled tasks inline, summarized, with a
path to the full text.

This requires a one-line change to
`~/.config/claude/scheduled-tasks/mac-software-updates/SKILL.md`: write the summary
to `~/.local/share/ai/mac-software-updates/YYYY-MM-DD.md`. Output predating that
change is not recoverable this way, so the review watermark starts at the date of
the change rather than backfilling.

The pattern generalizes: a scheduled task writes dated Markdown to
`~/.local/share/ai/<task-name>/`, and the `[watch]` section of `config.toml` lists
the directories Chief reads. Adding a task to the briefing is a one-line config
change, and each task's output stands on its own whether or not Chief reads it.

Unrelated but worth investigating separately: the `mac-software-updates` task
reports a `lastRunAt` of today, while its newest recorded run is 2026-08-27. Recent
runs may not be completing.

## Testing

Tests use Bun's test runner against a temporary `CHIEF_HOME`. The design makes this
tractable: the CLI's only I/O is the filesystem plus one `spawn()` call, so
injecting a fake spawner covers everything except the launch itself.

## Build Order

Each step is a commit, with tests written first.

0. **Spike (throwaway).** Launch `claude --bg --session-id …` in a worktree and
   check whether it appears in the desktop app sidebar, in `/resume`, and in Zed.
   The answer shapes step 7. Do not build adapters on an assumption.
1. **Registry and journal.** `chief init|list|note|close`, atomic writes.
2. **Spawn, Claude only.** Worktree, kickoff prompt, launch, record.
3. **Status.** `chief report` (push) and `chief digest` (pull); `chief briefing`.
4. **The Chief agent.** `AGENT.md` and the session-start flow.
5. **Reports.** The `mac-software-updates` change plus `chief updates`.
6. **Codex and OpenCode spawning**, including the model roster and probing.
7. **Surface adapters.** Terminal, then desktop app, then Zed.

Steps 1–4 are the usable core; 5–7 are additive. The tool is worth using after
step 4, while the rest is built.

## Open Risks

- **Session visibility across surfaces is unverified.** Whether a `--bg`
  CLI-spawned Claude session appears in the desktop app sidebar and in Zed decides
  how adapters work. Step 0 settles it before anything depends on it.
- **Codex mints its own session id** only after the first prompt, so a Codex worker
  is not queryable between launch and first send. The registry must tolerate a
  record whose harness id arrives late.
- **Worker Stop hooks are the primary status signal.** If a hook fails to fire, the
  pull path must be good enough to keep the briefing honest.

## Follow-On Work

- A pair-programming agent, for sessions where the human works alongside the AI
  rather than delegating. Named and designed separately, once Chief exists.
- Simultaneous multi-model collaboration, if sequential cross-check proves
  insufficient.
