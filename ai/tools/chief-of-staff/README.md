# chief

`chief` is the Chief of Staff CLI: it keeps a registry and journal of the AI
coding sessions in flight, so one place can answer "what is everyone doing?"
See the [design](../../docs/plans/2026-09-23-chief-of-staff-design.md).

Built with Bun and TypeScript. `install.sh` links `src/cli.ts` to `~/.local/bin/chief`.

## Starting Chief

Run `cos` (alias for `claude --agent chief-of-staff`, defined in `sh/ai.sh`).
The agent is defined in `ai/agents/chief-of-staff/AGENT.md`; OpenCode reads it
from `ai/agents/` too. Chief is not the default agent.

Workers Chief spawns:

- do not appear in the desktop app's sidebar; use the `attach.terminal` command
  from `chief briefing` (or `chief status <session>`) to enter one
- must be worktrees of a repository you have already trusted in Claude Code
  (run `claude` once in it), or the launch fails with "Workspace not trusted"

## Development

```sh
make install   # bun install
make specs     # bun test
make lint      # biome + tsc
make format    # biome --write
```

## State

Under `$CHIEF_HOME` (default `~/.local/share/ai/chief-of-staff`):

- `registry.json` — one record per session. A session stays listed, even after
  its worker reports `done`, until `chief close` sets its `closed_at`
- `journal/YYYY-MM.md` — append-only journal
- `hooks/` — per-session Claude settings JSON that installs the worker's Stop hook
- `config.toml` — the only hand-edited file; `chief init` writes a template once
  and never overwrites it. `[watch] dirs` lists directories where scheduled tasks
  write dated `YYYY-MM-DD.md` reports
- `reviewed.json` — per watched directory, the latest report date already reviewed

## Commands

```text
usage: chief <command> [options]

  init                                   create the state directory
  list [--all] [--json]                  sessions in flight
  status <session>                       one session's record
  note <text…>                           append to the journal
  close <session> [--abandon] [--summary <text>]
  spawn --goal <text> [--slug s] [--repo dir] [--harness claude] [--model m] [--effort e] [--autonomy auto|checkpointed]
  report <session> --state <state> [--waiting-on <checkpoint>] [--summary <text>]
  report <session> --stopped             (Stop hook; reads hook JSON on stdin)
  approve <session> [message…]           release a waiting worker
  digest <session> [--recent N]          summarize the worker's transcript
  updates [--mark-reviewed [--task name]]  unreviewed scheduled-task reports
  briefing                               everything a session start needs, as JSON
```

`<session>` is a full session id, the short id `claude attach` takes, a slug
(the latest session with it), or a unique id prefix of at least 4 characters.
