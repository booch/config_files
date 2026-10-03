# chief

`chief` is the Chief of Staff CLI: it keeps a registry and journal of the AI
coding sessions in flight, so one place can answer "what is everyone doing?"
See the [design](../../docs/plans/2026-09-23-chief-of-staff-design.md).

Built with Bun and TypeScript. `install.sh` links `src/cli.ts` to `~/.local/bin/chief`.

## Development

```sh
make install   # bun install
make specs     # bun test
make lint      # biome + tsc
make format    # biome --write
```

## State

Under `$CHIEF_HOME` (default `~/.local/share/ai/chief-of-staff`):

- `registry.json` — one record per session
- `journal/YYYY-MM.md` — append-only journal
- `hooks/` — hook scripts written for spawned sessions

## Commands

```text
init                                   create the state directory
list [--all] [--json]                  sessions in flight
status <session>                       one session's record
note <text…>                           append to the journal
close <session> [--abandon] [--summary <text>]
spawn --goal <text> [--slug s] [--repo dir] [--model m] [--effort e] [--autonomy auto|checkpointed]
report <session> --state <state> [--waiting-on <checkpoint>] [--summary <text>]
report <session> --stopped             (Stop hook; reads hook JSON on stdin)
approve <session> [message…]           release a waiting worker
```
