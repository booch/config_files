# Spike: Claude Code background sessions

Run 2026-10-02 with Claude Code 2.1.286, in a worktree of `~/.config` at
`~/.local/share/ai/worktrees/.config/chief-spike`. An earlier attempt
(2026-09-23) used a fresh `git init` scratch repo and was refused at the trust
gate; see question 0.

## Answers

| # | Question | Answer | Evidence |
| --- | --- | --- | --- |
| 0 | Does `--bg` need workspace trust? | **Yes**, resolved per git repository. A plain dir under trusted `$HOME` passes; a fresh `git init` repo in the same place fails; a `git worktree` of a trusted repo passes even in a never-trusted location. | `Workspace not trusted. Run claude in <dir> once and accept the trust prompt, then retry.` |
| 1 | What does `--bg` print? | `backgrounded · <short> · <name>` plus help lines including `claude attach <short>`. The short id is the first 8 hex of the session UUID. | `test/fixtures/claude-bg-output.txt` |
| 1a | Does `--bg` honor `--session-id`? | **No.** `warning: --bg manages the session id; ignoring --session-id`. | stderr of the launch |
| 1b | How to get the full session id? | `claude agents --json`: each entry has `id` (short), `sessionId` (full UUID), `cwd`, `name`, `status` (`busy`/`idle`), `state` (`working`/`done`), `pid`. | `jq '.[] \| select(.id=="ca42e85d")'` |
| 2 | Does a `--settings` Stop hook fire? Input keys? | Yes, after every turn. Keys: `session_id`, `transcript_path`, `cwd`, `last_assistant_message`, `stop_hook_active`, `permission_mode`, `effort`, `hook_event_name`, `prompt_id`, `scratchpad_dir`, `background_tasks`, `session_crons`. | hook wrote stdin to a file |
| 3 | Do the user's global Stop hooks also run? Block? | They run (7 hooks, including the prompt-type documentation review). They did not block the worker in this spike. | `claude logs` |
| 4 | Transcript path? | `~/.claude/projects/<cwd, non-alphanumerics → "-">/<sessionId>.jsonl` — matches the plan's formula, keyed by the **harness** session id. | `transcript_path` in hook input |
| 5 | Does `--bg --resume <uuid> "<msg>"` continue the same session? | Only once the session's process is gone. A session that finished its turn is still running (idle), so resume **starts a copy**. After `claude stop <short>` completes (it is asynchronous; wait until the id leaves `claude agents --json`), resume wakes the same session with its saved options (`--name`, `--effort`, `--permission-mode`, `--settings`, `--model`). The Stop hook keeps firing. | `note: woke session ca42e85d with its saved options` |
| 6 | Visible in the desktop app sidebar? `/resume`? Zed? | Sidebar: **no** (the app lists only its own `local_…` sessions). `/resume` should find it (the transcript is in the normal project dir); not tried interactively. Zed: needs a human check. | `ccd_session_mgmt list_sessions` |
| 7 | Does `--bg` accept `--agent`? | Yes. | `claude --bg --agent general-purpose …` started |
| 8 | Model caveat | With `--model haiku`, auto mode is unavailable and the session drops to manual mode, so a worker would stall on permission prompts. | probe log: `auto mode unavailable for this model` |

## Implications for the plan

- **Task 5:** drop `--session-id` from `launchArgv`. Add `claude agents --json` parsing to map the short id to the full session id, plus `claude stop`. `parseBgRef`'s `claude attach (\S+)` pattern matches the real output. `transcriptPath` and `resumeArgv` take the *harness* session id.
- **Task 1:** the record needs `harness_session_id` (full UUID, null until known) beside `harness_ref` (short id).
- **Task 6:** after launch, look up `harness_session_id` via `claude agents --json`.
- **Task 7:** the Stop hook input carries `session_id`; use it to fill `harness_session_id` if spawn could not.
- **Task 8:** approve = `claude stop <short>`, wait until it leaves `claude agents --json`, then `claude --bg --resume <session id> "<msg>"`.
- **Tasks 9–10:** transcript lookups use `harness_session_id`.
- **Task 11:** the agent should not pick Haiku for workers.
- **Step-7 plan:** no desktop-sidebar presence for CLI-spawned sessions; adapters cannot rely on it.
