# Chief of Staff — Implementation Plan (Core)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the usable core of the Chief of Staff: the `chief` CLI (registry, journal, Claude-only spawn, status push/pull, briefing, scheduled-task updates) and the Chief agent definition.

**Architecture:** A Bun + TypeScript CLI owns every deterministic mechanic and keeps harness-neutral state in plain files under `~/.local/share/ai/chief-of-staff/`. All I/O goes through an injected `Context` (paths, clock, process runner, stdin), so tests run against a temporary directory with real `git` and a fake `claude`. The Chief agent (`AGENT.md`) holds judgment only and calls the CLI.

**Tech Stack:** Bun 1.3 (runtime, test runner, `Bun.TOML`, `Bun.randomUUIDv7`), TypeScript (strict), `node:util` `parseArgs`, Biome (lint/format). No runtime dependencies.

**Spec:** [`ai/docs/plans/2026-09-23-chief-of-staff-design.md`](2026-09-23-chief-of-staff-design.md) — read it before starting any task.

## Scope

This plan covers design build-order steps **0–5**: the spike, the usable core
(steps 1–4), and scheduled-task reports (step 5).

Steps **6** (Codex and OpenCode spawning, model roster, probing) and **7** (surface
adapters) get their own plan, written after this one lands. Both depend on facts
this plan produces: step 7 on the spike's answers, step 6 on how the registry,
report, and digest seams hold up in real use. Writing their code now would mean
guessing at CLI output formats we have not observed.

## Global Constraints

- Tool location: `~/.config/ai/tools/chief-of-staff/`; executable name `chief`; symlinked to `~/.local/bin/chief` by `install.sh`.
- State location: `${CHIEF_HOME:-${XDG_DATA_HOME:-~/.local/share}/ai/chief-of-staff}` — `registry.json`, `journal/YYYY-MM.md`, `config.toml`, `reviewed.json`, `hooks/<id>.json`.
- `harness` ∈ `claude`, `codex`, `opencode`. `autonomy` ∈ `auto`, `checkpointed`. `state` ∈ `running`, `waiting`, `blocked`, `done`, `abandoned`.
- Session ids are UUIDv7 (`Bun.randomUUIDv7()`).
- `registry.json` is written atomically (temp file + rename), under a lock (see Task 1).
- The journal is append-only. Never rewrite it.
- Nothing in Chief hardcodes a model list. This plan passes `--model` straight through to `claude`.
- No runtime dependencies. Dev dependencies only: `@biomejs/biome`, `typescript`, `@types/bun`.
- No shell string interpolation when launching processes: always pass an argv array to `ctx.run`. Where a shell command string must be written (hook settings, kickoff prompt), quote with `shellQuote`.
- `make specs` and `make lint` (run in the tool directory) must pass before every commit.
- **Approval gates (from `~/.config/ai/AGENTS.md`):** for each task, show the human the tests before implementing, and get approval of the commit and message before committing — unless the human has said "continue without prompting." Run the 3-reviewer process (`/review`) before each commit.
- Commit messages: `Chief: <imperative summary>` subject; trailer `AI-Generated-By: Claude Opus 5.5 (claude-opus-5-5) via Claude Code (<version>)`. Never `Co-Authored-By`. Invoke the `commits` skill before committing.
- This is a public repo: never commit tokens, transcripts, or personal data. Test fixtures must be synthetic.

## Deviations From the Spec

Called out so a reviewer can accept or reject them explicitly:

1. **`harness_ref` field added to the registry record.** `claude attach` takes the *short* id that `claude --bg` prints, not the session UUID (verified: `claude --help`, v2.1.281). Codex will also mint its own id late (spec Open Risks). `harness_ref: string | null` holds the harness's own handle.
2. **`summary` field added.** `chief report --summary` needs somewhere to live; the briefing shows it.
3. **Registry lock.** Atomic rename prevents corruption but not lost updates when two workers' Stop hooks fire at once. A `mkdir`-based lock around read-modify-write fixes that.
4. **Unreported stop ⇒ waiting.** If a worker's Stop hook fires while its state is still `running`, Chief marks it `waiting` on `unreported-stop`. A worker that stopped without saying why needs a human look.
5. **`chief approve` command.** The spec says approving "writes the approval into the worker's session." This is the mechanism: `claude --bg --resume <uuid> "<message>"`, which `claude --help` documents as continuing a background session under the same id. The spike confirms it.
6. **Kickoff prompt grants "continue without prompting."** A worker loads the global `AGENTS.md`, whose approval checkpoints would stall an `auto` worker on every step. The kickoff prompt invokes that file's documented "continue without prompting" exception, carving out the always-escalate tier.

## Open Questions for the Human

Answer before Task 11. None of them block Tasks 0–10.

1. **Making Chief the default entry point.** Setting `"agent": "chief-of-staff"` in `claude/settings.json` would also make every *worker* spawned by `claude --bg` start as Chief. This plan adds a `cos` alias instead (`claude --agent chief-of-staff`). Revisit once the spike shows whether `--agent` can be overridden per launch.
2. **Worktree root.** The spec example puts worktrees under `~/.local/share/claude/worktrees/`, matching existing worktrees. That is Claude-named, while Codex and OpenCode workers will use it too. Keep it (this plan's default), or move to `~/.local/share/ai/worktrees/`?

## File Structure

```text
ai/tools/chief-of-staff/
  package.json, bun.lock, tsconfig.json, biome.json, bunfig.toml, Makefile, .gitignore, README.md
  docs/spike-notes.md          # Task 0 findings
  src/
    cli.ts                     # entry point: parse argv, dispatch, print; no logic
    context.ts                 # Context, Runner, ChiefError, defaultContext, realRunner
    files.ts                   # readTextIfExists, writeAtomically, isNotFound
    text.ts                    # oneLine, truncate, firstLine, shellQuote, expandHome
    time.ts                    # ymd, yyyymm, hm, minutesBetween (local time)
    registry.ts                # SessionRecord + load / add / update / find (locked, atomic)
    journal.ts                 # appendJournal, tailJournal
    worktree.ts                # createWorktree
    kickoff.ts                 # kickoffPrompt, slugify, validateSlug
    harness/claude.ts          # argv builders, bg-output parser, hook settings, transcript path + parser
    spawn.ts                   # spawnSession orchestration
    report.ts                  # reportState, reportStopped
    approve.ts                 # approveSession
    digest.ts                  # digestSession
    quota.ts                   # readQuota
    config.ts                  # loadConfig, CONFIG_TEMPLATE
    updates.ts                 # unreviewedUpdates, markReviewed, highlights
    briefing.ts                # buildBriefing
  test/
    setup.ts                   # TZ=UTC preload
    helpers.ts                 # testContext, makeGitRepo
    fixtures/claude-bg-output.txt       # from the spike
    fixtures/claude-transcript.jsonl    # synthetic
    *.test.ts                  # one per src module
ai/agents/chief-of-staff/AGENT.md
opencode/agents/chief-of-staff.md → ../../ai/agents/chief-of-staff/AGENT.md
```

Also modified: `install.sh` (symlink), `git/ignore` (kickoff file), `sh/ai.sh` (`cos` alias),
`claude/scheduled-tasks/mac-software-updates/SKILL.md` (Task 13; this file is not tracked in git).

---

### Task 0: Spike — background session behavior (throwaway)

No production code. Output: `docs/spike-notes.md` and one fixture. Every later
assumption about `claude --bg` traces back to this file.

**Files:**

- Create: `ai/tools/chief-of-staff/docs/spike-notes.md`
- Create: `ai/tools/chief-of-staff/test/fixtures/claude-bg-output.txt`

- [ ] **Step 1: Make a scratch worktree and hook file**

```bash
git -C ~/.config worktree add -b chief-spike ~/.local/share/claude/worktrees/.config/chief-spike
mkdir -p /tmp/chief-spike
cat > /tmp/chief-spike/hooks.json <<'EOF'
{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"cat > /tmp/chief-spike/stop-input.json","timeout":30}]}]}}
EOF
```

- [ ] **Step 2: Launch a background session and capture its output**

```bash
uuid=$(bun -e 'console.log(Bun.randomUUIDv7())')
echo "$uuid" > /tmp/chief-spike/uuid
claude --bg --session-id "$uuid" --name chief-spike --model sonnet --effort low \
  --permission-mode auto --settings /tmp/chief-spike/hooks.json \
  "Create a file named SPIKE.txt containing the word hello, then stop." \
  | tee /tmp/chief-spike/bg-output.txt
```

Wait for it to finish (`claude agents` lists it).

- [ ] **Step 3: Answer each question and record it in `docs/spike-notes.md`**

| # | Question | How to check |
| --- | --- | --- |
| 1 | What exactly does `--bg` print? Which token is the short id for `claude attach`? | `cat /tmp/chief-spike/bg-output.txt` |
| 2 | Did the `--settings` Stop hook fire? What keys are in its input (`session_id`, `transcript_path`, `last_assistant_message`, `stop_hook_active`)? | `jq 'keys' /tmp/chief-spike/stop-input.json` |
| 3 | Do the user's global Stop hooks (e.g. `task-complete-enforcer.ts`) also run, and do they block the worker? | `claude logs <short-id>` |
| 4 | Transcript path: is it `~/.claude/projects/<worktree path with every non-alphanumeric char → "-">/<uuid>.jsonl`? | `ls ~/.claude/projects/ \| grep chief-spike` |
| 5 | Does `claude --bg --resume <uuid> "Now append world."` continue the *same* idle session (same id), or start a copy? | Run it; compare `claude agents` and the transcript |
| 6 | Does the session appear in the desktop app sidebar? In `/resume` from a terminal in the worktree? In Zed's agent panel? | Look |
| 7 | Can `claude --bg` take `--agent <name>`, so a default-agent setting could be overridden per worker? | `claude --bg --agent general-purpose "echo hi"` |

- [ ] **Step 4: Save the fixture**

```bash
cp /tmp/chief-spike/bg-output.txt ~/.config/ai/tools/chief-of-staff/test/fixtures/claude-bg-output.txt
```

Inspect it: if it contains anything personal (paths are fine, tokens are not), redact by hand.

- [ ] **Step 5: Clean up**

```bash
claude stop <short-id>
claude rm <short-id>
git -C ~/.config worktree remove --force ~/.local/share/claude/worktrees/.config/chief-spike
git -C ~/.config branch -D chief-spike
```

- [ ] **Step 6: Reconcile the plan.** If any answer contradicts an assumption in
  Tasks 5, 7, 8, or 9 (bg output shape, hook input keys, transcript path, resume
  semantics), update those tasks' code in this plan before starting them, and tell
  the human what changed. Question 6 feeds the step-7 plan only.

- [ ] **Step 7: Commit** `docs/spike-notes.md` and the fixture together with Task 1 (the directory does not exist as a package yet).

---

### Task 1: Scaffold and session registry

**Files:**

- Create: `ai/tools/chief-of-staff/{package.json,tsconfig.json,biome.json,bunfig.toml,Makefile,.gitignore}`
- Create: `src/context.ts`, `src/files.ts`, `src/registry.ts`
- Create: `test/setup.ts`, `test/helpers.ts`, `test/registry.test.ts`

(Paths under `src/` and `test/` are relative to `ai/tools/chief-of-staff/` from here on.)

**Interfaces:**

- Produces:
    - `interface RunResult { exitCode: number; stdout: string; stderr: string }`
    - `type Runner = (argv: string[], options?: { cwd?: string }) => Promise<RunResult>`
    - `interface Context { home; claudeHome; worktreeRoot; cliPath: string; now(): Date; run: Runner; stdin(): Promise<string> }`
    - `class ChiefError extends Error`
    - `defaultContext(env?): Context`, `realRunner: Runner`
    - `readTextIfExists(path): Promise<string | null>`, `writeAtomically(path, content): Promise<void>`
    - `SessionRecord`, `Harness`, `SessionState`, `Autonomy`, `HARNESSES`, `STATES`, `AUTONOMIES`, `isActive(record)`
    - `loadRegistry(ctx): Promise<SessionRecord[]>`
    - `addSession(ctx, record): Promise<void>`
    - `updateSession(ctx, id, change: (s: SessionRecord) => Partial<SessionRecord>): Promise<SessionRecord>`
    - `findSession(ctx, ref: string): Promise<SessionRecord>` — ref is a full id, a unique id prefix (≥ 4 chars), or a slug
    - Test helpers: `testContext(options?)`, `makeGitRepo(root)`, `sampleRecord(overrides?)`

- [ ] **Step 1: Scaffold the package**

`package.json`:

```json
{
    "name": "chief-of-staff",
    "private": true,
    "type": "module",
    "bin": { "chief": "src/cli.ts" },
    "devDependencies": {
        "@biomejs/biome": "^2.0.0",
        "@types/bun": "latest",
        "typescript": "^5.6.0"
    }
}
```

`tsconfig.json`:

```json
{
    "compilerOptions": {
        "target": "ESNext",
        "module": "ESNext",
        "moduleResolution": "bundler",
        "types": ["bun"],
        "strict": true,
        "noUncheckedIndexedAccess": true,
        "verbatimModuleSyntax": true,
        "skipLibCheck": true,
        "noEmit": true
    },
    "include": ["src", "test"]
}
```

`biome.json`:

```json
{
    "vcs": { "enabled": true, "clientKind": "git", "useIgnoreFile": true },
    "formatter": { "indentStyle": "space", "indentWidth": 4, "lineWidth": 100 },
    "linter": { "enabled": true, "rules": { "recommended": true } }
}
```

`bunfig.toml`:

```toml
[test]
preload = ["./test/setup.ts"]
```

`Makefile` (one-line `target: ; recipe` rules, so no tabs are needed):

```make
.PHONY: install specs lint
install: ; bun install
specs: ; bun test
lint: ; bunx biome check . && bunx tsc --noEmit
```

`.gitignore`:

```text
node_modules/
```

`test/setup.ts`:

```ts
// Journal headings and timestamps use local time; pin it so tests are deterministic.
process.env.TZ = "UTC";
```

Run: `make -C ~/.config/ai/tools/chief-of-staff install`
Expected: `bun.lock` created, no errors.

- [ ] **Step 2: Write `src/context.ts` and `src/files.ts`** (infrastructure the tests need; no behavior to specify)

`src/context.ts`:

```ts
import { homedir } from "node:os";
import { join, resolve } from "node:path";

export interface RunResult {
    exitCode: number;
    stdout: string;
    stderr: string;
}

export type Runner = (argv: string[], options?: { cwd?: string }) => Promise<RunResult>;

// Everything the CLI touches outside its own memory. Tests swap in temp dirs, a fixed clock,
// and a runner that fakes `claude`.
export interface Context {
    home: string; // Chief's state directory
    claudeHome: string; // ~/.claude: transcripts and the quota file
    worktreeRoot: string; // parent of spawned worktrees
    cliPath: string; // absolute path to cli.ts, for commands written into hooks and prompts
    now: () => Date;
    run: Runner;
    stdin: () => Promise<string>;
}

export class ChiefError extends Error {}

export const realRunner: Runner = async (argv, options = {}) => {
    const proc = Bun.spawn(argv, { cwd: options.cwd, stdin: "ignore", stdout: "pipe", stderr: "pipe" });
    const [stdout, stderr, exitCode] = await Promise.all([
        new Response(proc.stdout).text(),
        new Response(proc.stderr).text(),
        proc.exited,
    ]);
    return { exitCode, stdout, stderr };
};

export function defaultContext(env: Record<string, string | undefined> = process.env): Context {
    const dataHome = env.XDG_DATA_HOME ?? join(homedir(), ".local/share");
    return {
        home: env.CHIEF_HOME ?? join(dataHome, "ai/chief-of-staff"),
        claudeHome: env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude"),
        worktreeRoot: env.CHIEF_WORKTREE_ROOT ?? join(dataHome, "claude/worktrees"),
        cliPath: resolve(import.meta.dir, "cli.ts"),
        now: () => new Date(),
        run: realRunner,
        stdin: () => Bun.stdin.text(),
    };
}
```

`src/files.ts`:

```ts
import { readFile, rename, writeFile } from "node:fs/promises";

export function isNotFound(error: unknown): boolean {
    return (error as NodeJS.ErrnoException)?.code === "ENOENT";
}

export async function readTextIfExists(path: string): Promise<string | null> {
    try {
        return await readFile(path, "utf8");
    } catch (error) {
        if (isNotFound(error)) return null;
        throw error;
    }
}

// Readers never see a half-written file: write beside the target, then rename over it.
export async function writeAtomically(path: string, content: string): Promise<void> {
    const temp = `${path}.${process.pid}.${crypto.randomUUID()}.tmp`;
    await writeFile(temp, content);
    await rename(temp, path);
}
```

- [ ] **Step 3: Write the test helpers**

`test/helpers.ts`:

```ts
import { mkdirSync, mkdtempSync, realpathSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { type Context, type RunResult, realRunner } from "../src/context";
import type { SessionRecord } from "../src/registry";

export interface RecordedCall {
    argv: string[];
    cwd?: string;
}

export interface TestContextOptions {
    now?: string;
    stdin?: string;
    // Canned results for non-git commands, keyed by argv[0] (e.g. "claude").
    fakes?: Record<string, Partial<RunResult>>;
}

// Real git (fast, filesystem-only); everything else is recorded and faked.
export function testContext(options: TestContextOptions = {}) {
    const root = realpathSync(mkdtempSync(join(tmpdir(), "chief-test-")));
    const calls: RecordedCall[] = [];
    let current = new Date(options.now ?? "2026-09-23T14:02:00Z");
    const ctx: Context = {
        home: join(root, "home"),
        claudeHome: join(root, "claude"),
        worktreeRoot: join(root, "worktrees"),
        cliPath: "/opt/chief/src/cli.ts",
        now: () => current,
        run: async (argv, runOptions) => {
            if (argv[0] === "git") return realRunner(argv, runOptions);
            calls.push({ argv, cwd: runOptions?.cwd });
            return { exitCode: 0, stdout: "", stderr: "", ...options.fakes?.[argv[0] ?? ""] };
        },
        stdin: async () => options.stdin ?? "",
    };
    mkdirSync(ctx.home, { recursive: true });
    return {
        ctx,
        root,
        calls,
        setNow: (iso: string) => {
            current = new Date(iso);
        },
        cleanup: () => rmSync(root, { recursive: true, force: true }),
    };
}

export async function makeGitRepo(root: string, name = "repo"): Promise<string> {
    const dir = join(root, name);
    mkdirSync(dir, { recursive: true });
    for (const args of [
        ["init", "-q", "-b", "main"],
        ["-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-q", "--allow-empty", "-m", "init"],
    ]) {
        const result = await realRunner(["git", "-C", dir, ...args]);
        if (result.exitCode !== 0) throw new Error(result.stderr);
    }
    return dir;
}

export function sampleRecord(overrides: Partial<SessionRecord> = {}): SessionRecord {
    return {
        id: "01a0d1ea-6d1d-7000-834f-27da05c179e5",
        slug: "chief-cli",
        goal: "Implement chief spawn + registry",
        harness: "claude",
        harness_ref: "5f3a9c",
        model: "opus",
        effort: "high",
        repo: "/repo",
        worktree: "/worktrees/repo/chief-cli",
        branch: "chief-cli",
        autonomy: "auto",
        state: "running",
        waiting_on: null,
        summary: null,
        cross_check: null,
        spawned_at: "2026-09-23T14:02:00.000Z",
        last_activity_at: "2026-09-23T14:02:00.000Z",
        attach: { terminal: "claude attach 5f3a9c", resume: "cd '/worktrees/repo/chief-cli' && claude --resume 01a0d1ea-6d1d-7000-834f-27da05c179e5" },
        ...overrides,
    };
}
```

- [ ] **Step 4: Write the failing registry tests**

`test/registry.test.ts`:

```ts
import { afterEach, describe, expect, test } from "bun:test";
import { readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { ChiefError } from "../src/context";
import { addSession, findSession, isActive, loadRegistry, updateSession } from "../src/registry";
import { sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

describe("loadRegistry", () => {
    test("is empty when no registry file exists yet", async () => {
        env = testContext();
        expect(await loadRegistry(env.ctx)).toEqual([]);
    });

    test("refuses to guess when the file is corrupt, naming the file", async () => {
        env = testContext();
        writeFileSync(join(env.ctx.home, "registry.json"), "{not json");
        await expect(loadRegistry(env.ctx)).rejects.toThrow(/registry\.json/);
    });
});

describe("addSession", () => {
    test("persists the record", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        expect(await loadRegistry(env.ctx)).toEqual([sampleRecord()]);
    });

    test("leaves no temp or lock files behind", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        expect(readdirSync(env.ctx.home)).toEqual(["registry.json"]);
    });

    test("loses no records when many writers race", async () => {
        env = testContext();
        const ids = Array.from({ length: 20 }, (_, i) => `id-${i}`);
        await Promise.all(ids.map((id) => addSession(env.ctx, sampleRecord({ id, slug: id }))));
        const stored = (await loadRegistry(env.ctx)).map((s) => s.id).sort();
        expect(stored).toEqual([...ids].sort());
    });

    test("rejects a duplicate id", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await expect(addSession(env.ctx, sampleRecord())).rejects.toThrow(ChiefError);
    });
});

describe("updateSession", () => {
    test("applies the change and returns the updated record", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        const updated = await updateSession(env.ctx, sampleRecord().id, () => ({ state: "done" }));
        expect(updated.state).toBe("done");
        expect((await loadRegistry(env.ctx))[0]?.state).toBe("done");
    });

    test("hands the change function the current record", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ summary: "before" }));
        await updateSession(env.ctx, sampleRecord().id, (s) => ({ summary: `${s.summary}+after` }));
        expect((await loadRegistry(env.ctx))[0]?.summary).toBe("before+after");
    });

    test("never lets a change rewrite the id", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        const updated = await updateSession(env.ctx, sampleRecord().id, () => ({ id: "other" }));
        expect(updated.id).toBe(sampleRecord().id);
    });

    test("throws for an unknown id", async () => {
        env = testContext();
        await expect(updateSession(env.ctx, "nope", () => ({}))).rejects.toThrow(ChiefError);
    });
});

describe("findSession", () => {
    const first = sampleRecord({ id: "0190aaaa-0000-7000-8000-000000000001", slug: "alpha", state: "done" });
    const second = sampleRecord({ id: "0190bbbb-0000-7000-8000-000000000002", slug: "alpha" });

    test("finds by full id, unique prefix, or slug (latest wins)", async () => {
        env = testContext();
        await addSession(env.ctx, first);
        await addSession(env.ctx, second);
        expect((await findSession(env.ctx, first.id)).id).toBe(first.id);
        expect((await findSession(env.ctx, "0190aa")).id).toBe(first.id);
        expect((await findSession(env.ctx, "alpha")).id).toBe(second.id);
    });

    test("rejects ambiguous or too-short prefixes, and unknown refs", async () => {
        env = testContext();
        await addSession(env.ctx, first);
        await addSession(env.ctx, second);
        await expect(findSession(env.ctx, "0190")).rejects.toThrow(/ambiguous/);
        await expect(findSession(env.ctx, "019")).rejects.toThrow(ChiefError);
        await expect(findSession(env.ctx, "missing")).rejects.toThrow(/no session/);
    });
});

test("isActive excludes done and abandoned sessions", () => {
    expect(isActive(sampleRecord({ state: "waiting" }))).toBe(true);
    expect(isActive(sampleRecord({ state: "done" }))).toBe(false);
    expect(isActive(sampleRecord({ state: "abandoned" }))).toBe(false);
});
```

- [ ] **Step 5: Run the tests to verify they fail**

Run: `bun test test/registry.test.ts` (from the tool directory)
Expected: FAIL — `Cannot find module '../src/registry'`.

- [ ] **Step 6: Implement `src/registry.ts`**

```ts
import { mkdir, rm, stat } from "node:fs/promises";
import { join } from "node:path";
import { ChiefError, type Context } from "./context";
import { isNotFound, readTextIfExists, writeAtomically } from "./files";

export const HARNESSES = ["claude", "codex", "opencode"] as const;
export const STATES = ["running", "waiting", "blocked", "done", "abandoned"] as const;
export const AUTONOMIES = ["auto", "checkpointed"] as const;
export type Harness = (typeof HARNESSES)[number];
export type SessionState = (typeof STATES)[number];
export type Autonomy = (typeof AUTONOMIES)[number];

export interface SessionRecord {
    id: string;
    slug: string;
    goal: string;
    harness: Harness;
    harness_ref: string | null; // the harness's own handle (e.g. the short id `claude attach` takes)
    model: string;
    effort: string;
    repo: string;
    worktree: string;
    branch: string;
    autonomy: Autonomy;
    state: SessionState;
    waiting_on: string | null;
    summary: string | null;
    cross_check: string | null;
    spawned_at: string;
    last_activity_at: string;
    attach: { terminal: string | null; resume: string };
}

const MIN_PREFIX = 4;
const LOCK_TIMEOUT_MS = 5_000;
const STALE_LOCK_MS = 30_000;
const LOCK_RETRY_MS = 20;

export function isActive(session: SessionRecord): boolean {
    return session.state !== "done" && session.state !== "abandoned";
}

export async function loadRegistry(ctx: Context): Promise<SessionRecord[]> {
    const path = registryPath(ctx);
    const text = await readTextIfExists(path);
    if (text === null) return [];
    try {
        return JSON.parse(text).sessions;
    } catch (error) {
        throw new ChiefError(`${path} is not valid JSON (${(error as Error).message}); fix or move it aside`);
    }
}

export async function addSession(ctx: Context, record: SessionRecord): Promise<void> {
    await mutateRegistry(ctx, (sessions) => {
        if (sessions.some((s) => s.id === record.id)) throw new ChiefError(`duplicate session id ${record.id}`);
        return [...sessions, record];
    });
}

export async function updateSession(
    ctx: Context,
    id: string,
    change: (session: SessionRecord) => Partial<SessionRecord>,
): Promise<SessionRecord> {
    const sessions = await mutateRegistry(ctx, (all) => {
        if (!all.some((s) => s.id === id)) throw new ChiefError(`no session with id ${id}`);
        return all.map((s) => (s.id === id ? { ...s, ...change(s), id } : s));
    });
    return sessions.find((s) => s.id === id) as SessionRecord;
}

export async function findSession(ctx: Context, ref: string): Promise<SessionRecord> {
    const sessions = await loadRegistry(ctx);
    const exact = sessions.find((s) => s.id === ref);
    if (exact) return exact;
    const bySlug = sessions.filter((s) => s.slug === ref).at(-1);
    if (bySlug) return bySlug;
    if (ref.length >= MIN_PREFIX) {
        const byPrefix = sessions.filter((s) => s.id.startsWith(ref));
        if (byPrefix.length > 1) throw new ChiefError(`"${ref}" is ambiguous: ${byPrefix.map((s) => s.slug).join(", ")}`);
        if (byPrefix[0]) return byPrefix[0];
    }
    throw new ChiefError(`no session matches "${ref}"`);
}

function registryPath(ctx: Context): string {
    return join(ctx.home, "registry.json");
}

// Returns the sessions as written.
async function mutateRegistry(
    ctx: Context,
    mutate: (sessions: SessionRecord[]) => SessionRecord[],
): Promise<SessionRecord[]> {
    await mkdir(ctx.home, { recursive: true });
    return withLock(join(ctx.home, "registry.lock"), async () => {
        const sessions = mutate(await loadRegistry(ctx));
        await writeAtomically(registryPath(ctx), `${JSON.stringify({ version: 1, sessions }, null, 2)}\n`);
        return sessions;
    });
}

// mkdir is atomic, so it doubles as a cross-process mutex. A lock older than STALE_LOCK_MS
// belongs to a crashed process and is broken.
async function withLock<T>(lock: string, body: () => Promise<T>): Promise<T> {
    const deadline = Date.now() + LOCK_TIMEOUT_MS;
    while (!(await tryLock(lock))) {
        if (await isStale(lock)) await rm(lock, { recursive: true, force: true });
        else if (Date.now() > deadline) throw new ChiefError(`registry is locked (${lock}); remove it if no chief is running`);
        else await Bun.sleep(LOCK_RETRY_MS);
    }
    try {
        return await body();
    } finally {
        await rm(lock, { recursive: true, force: true });
    }
}

async function tryLock(lock: string): Promise<boolean> {
    try {
        await mkdir(lock);
        return true;
    } catch (error) {
        if ((error as NodeJS.ErrnoException).code === "EEXIST") return false;
        throw error;
    }
}

async function isStale(lock: string): Promise<boolean> {
    try {
        return Date.now() - (await stat(lock)).mtimeMs > STALE_LOCK_MS;
    } catch (error) {
        return isNotFound(error); // released between our mkdir and stat: retry immediately
    }
}
```

Note on the slug-before-prefix order in `findSession`: an exact slug is a stronger
signal than a prefix. The test `findSession(env.ctx, "0190")` still sees ambiguity
because no slug is `"0190"`.

- [ ] **Step 7: Run tests and lint**

Run: `make specs && make lint`
Expected: all registry tests PASS; Biome and tsc clean. Fix formatting with `bunx biome check --write .` if needed.

- [ ] **Step 8: Commit** (after review and approval)

```bash
git -C ~/.config add ai/tools/chief-of-staff
git -C ~/.config commit -m "Chief: Add CLI scaffold and session registry" -m "Registry writes are atomic and serialized by a mkdir lock, so concurrent worker Stop hooks cannot drop each other's updates. Includes the Task 0 spike notes." -m "AI-Generated-By: Claude Opus 5.5 (claude-opus-5-5) via Claude Code (<version>)"
```

---

### Task 2: Journal

**Files:**

- Create: `src/time.ts`, `src/text.ts`, `src/journal.ts`
- Test: `test/journal.test.ts`, `test/text.test.ts`

**Interfaces:**

- Consumes: `Context`, `readTextIfExists`
- Produces:
    - `ymd(d): string` (`2026-09-23`), `yyyymm(d): string` (`2026-09`), `hm(d): string` (`14:02`), `minutesBetween(fromIso: string, to: Date): number` — all local time
    - `oneLine(s): string`, `truncate(s, max): string`, `firstLine(s): string`, `shellQuote(s): string`, `expandHome(path): string`
    - `appendJournal(ctx, text): Promise<void>`, `tailJournal(ctx, count): Promise<string[]>`

- [ ] **Step 1: Write the failing tests**

`test/text.test.ts`:

```ts
import { expect, test } from "bun:test";
import { homedir } from "node:os";
import { expandHome, firstLine, oneLine, shellQuote, truncate } from "../src/text";

test("oneLine collapses newlines and runs of whitespace", () => {
    expect(oneLine("  a\n\n## b\t c ")).toBe("a ## b c");
});

test("truncate adds an ellipsis only when it cuts", () => {
    expect(truncate("short", 10)).toBe("short");
    expect(truncate("0123456789abc", 10)).toBe("012345678…");
});

test("firstLine returns the first non-blank line, trimmed", () => {
    expect(firstLine("\n  error: boom \nmore")).toBe("error: boom");
    expect(firstLine("")).toBe("");
});

test("shellQuote survives single quotes and spaces", () => {
    expect(shellQuote("/a b/it's")).toBe(`'/a b/it'\\''s'`);
});

test("expandHome expands only a leading ~/", () => {
    expect(expandHome("~/x")).toBe(`${homedir()}/x`);
    expect(expandHome("/a/~/x")).toBe("/a/~/x");
});
```

`test/journal.test.ts`:

```ts
import { afterEach, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { appendJournal, tailJournal } from "../src/journal";
import { testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const journalFile = (month: string) => readFileSync(join(env.ctx.home, "journal", `${month}.md`), "utf8");

test("starts a month file with a day heading and a timestamped bullet", async () => {
    env = testContext({ now: "2026-09-23T14:02:00Z" });
    await appendJournal(env.ctx, "spawned `chief-cli`");
    expect(journalFile("2026-09")).toBe("## 2026-09-23\n\n- 14:02 spawned `chief-cli`\n");
});

test("adds a heading only when the day changes", async () => {
    env = testContext({ now: "2026-09-23T14:02:00Z" });
    await appendJournal(env.ctx, "one");
    env.setNow("2026-09-23T15:05:00Z");
    await appendJournal(env.ctx, "two");
    env.setNow("2026-09-24T09:00:00Z");
    await appendJournal(env.ctx, "three");
    expect(journalFile("2026-09")).toBe(
        "## 2026-09-23\n\n- 14:02 one\n- 15:05 two\n\n## 2026-09-24\n\n- 09:00 three\n",
    );
});

test("keeps each entry on one line, so text cannot forge headings", async () => {
    env = testContext();
    await appendJournal(env.ctx, "summary\n## 2020-01-01\n- fake");
    expect(journalFile("2026-09")).toContain("- 14:02 summary ## 2020-01-01 - fake\n");
});

test("tail spans the month boundary and returns the most recent lines", async () => {
    env = testContext({ now: "2026-08-31T23:00:00Z" });
    await appendJournal(env.ctx, "august");
    env.setNow("2026-09-01T08:00:00Z");
    await appendJournal(env.ctx, "september");
    expect(await tailJournal(env.ctx, 3)).toEqual(["- 23:00 august", "## 2026-09-01", "- 08:00 september"]);
});

test("tail is empty before anything is journaled", async () => {
    env = testContext();
    expect(await tailJournal(env.ctx, 5)).toEqual([]);
});
```

- [ ] **Step 2: Run to verify they fail**

Run: `bun test test/text.test.ts test/journal.test.ts`
Expected: FAIL — modules not found.

- [ ] **Step 3: Implement**

`src/text.ts`:

```ts
import { homedir } from "node:os";
import { join } from "node:path";

export function oneLine(text: string): string {
    return text.replace(/\s+/g, " ").trim();
}

export function truncate(text: string, max: number): string {
    return text.length <= max ? text : `${text.slice(0, max - 1)}…`;
}

export function firstLine(text: string): string {
    return text.split("\n").map((line) => line.trim()).find(Boolean) ?? "";
}

export function shellQuote(text: string): string {
    return `'${text.replaceAll("'", `'\\''`)}'`;
}

export function expandHome(path: string): string {
    return path.startsWith("~/") ? join(homedir(), path.slice(2)) : path;
}
```

`src/time.ts`:

```ts
// Local time throughout: the journal is for a human reading it in their own time zone.
const pad = (n: number) => String(n).padStart(2, "0");

export const yyyymm = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}`;
export const ymd = (d: Date) => `${yyyymm(d)}-${pad(d.getDate())}`;
export const hm = (d: Date) => `${pad(d.getHours())}:${pad(d.getMinutes())}`;

export function minutesBetween(fromIso: string, to: Date): number {
    return Math.max(0, Math.floor((to.getTime() - Date.parse(fromIso)) / 60_000));
}
```

`src/journal.ts`:

```ts
import { appendFile, mkdir } from "node:fs/promises";
import { join } from "node:path";
import type { Context } from "./context";
import { readTextIfExists } from "./files";
import { oneLine } from "./text";
import { hm, ymd, yyyymm } from "./time";

export async function appendJournal(ctx: Context, text: string): Promise<void> {
    const now = ctx.now();
    const dir = journalDir(ctx);
    await mkdir(dir, { recursive: true });
    const file = join(dir, `${yyyymm(now)}.md`);
    const existing = (await readTextIfExists(file)) ?? "";
    const heading = `## ${ymd(now)}`;
    const opening = lastHeading(existing) === heading ? "" : `${existing ? "\n" : ""}${heading}\n\n`;
    await appendFile(file, `${opening}- ${hm(now)} ${oneLine(text)}\n`);
}

export async function tailJournal(ctx: Context, count: number): Promise<string[]> {
    const now = ctx.now();
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const texts = await Promise.all(
        [lastMonth, now].map((d) => readTextIfExists(join(journalDir(ctx), `${yyyymm(d)}.md`))),
    );
    const lines = texts.flatMap((text) => (text ?? "").split("\n")).filter((line) => line.trim());
    return lines.slice(-count);
}

function journalDir(ctx: Context): string {
    return join(ctx.home, "journal");
}

function lastHeading(text: string): string | undefined {
    return text.split("\n").filter((line) => line.startsWith("## ")).at(-1);
}
```

- [ ] **Step 4: Run tests and lint** — `make specs && make lint` → PASS.

- [ ] **Step 5: Commit** — `Chief: Add append-only journal`

---

### Task 3: CLI entry point — `init`, `list`, `status`, `note`, `close`

**Files:**

- Create: `src/cli.ts`, `src/commands.ts`, `README.md`
- Modify: `install.sh` (after line 256, beside the other `~/.local/bin` links)
- Test: `test/commands.test.ts`

**Interfaces:**

- Consumes: registry and journal functions from Tasks 1–2
- Produces:
    - `type CommandResult = { output: string }` — what the CLI prints
    - `runCommand(ctx, argv: string[]): Promise<CommandResult>` — the dispatcher; later tasks add entries to its `COMMANDS` table
    - `initHome(ctx): Promise<void>`, `closeSession(ctx, ref, state, summary?)`

Design: `cli.ts` is a ten-line shell around `runCommand`, which is fully testable.
Every command prints JSON except `list`, which prints one line per session for
humans (`list --json` prints JSON).

- [ ] **Step 1: Write the failing tests**

`test/commands.test.ts`:

```ts
import { afterEach, describe, expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { runCommand } from "../src/commands";
import { addSession, loadRegistry } from "../src/registry";
import { sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const run = (...argv: string[]) => runCommand(env.ctx, argv);

describe("init", () => {
    test("creates the state layout and is idempotent", async () => {
        env = testContext();
        await run("init");
        await addSession(env.ctx, sampleRecord());
        await run("init");
        expect(existsSync(join(env.ctx.home, "journal"))).toBe(true);
        expect(existsSync(join(env.ctx.home, "hooks"))).toBe(true);
        expect(await loadRegistry(env.ctx)).toHaveLength(1);
    });
});

describe("list", () => {
    test("shows active sessions, one line each", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ id: "a1", slug: "live", state: "waiting", waiting_on: "approve-tests" }));
        await addSession(env.ctx, sampleRecord({ id: "b2", slug: "old", state: "done" }));
        const { output } = await run("list");
        expect(output).toContain("live");
        expect(output).toContain("waiting on approve-tests");
        expect(output).not.toContain("old");
    });

    test("--all includes closed sessions; --json emits records", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ state: "done" }));
        expect((await run("list", "--all")).output).toContain("chief-cli");
        expect(JSON.parse((await run("list", "--all", "--json")).output)).toHaveLength(1);
    });

    test("says so when nothing is in flight", async () => {
        env = testContext();
        expect((await run("list")).output).toBe("No sessions in flight.");
    });
});

test("status prints the record as JSON", async () => {
    env = testContext();
    await addSession(env.ctx, sampleRecord());
    expect(JSON.parse((await run("status", "chief-cli")).output).id).toBe(sampleRecord().id);
});

test("note journals free text", async () => {
    env = testContext();
    await run("note", "decided", "not", "to", "escalate");
    expect(readFileSync(join(env.ctx.home, "journal", "2026-09.md"), "utf8")).toContain("- 14:02 decided not to escalate");
});

describe("close", () => {
    test("marks done with a summary and journals it", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await run("close", "chief-cli", "--summary", "merged");
        const [record] = await loadRegistry(env.ctx);
        expect(record?.state).toBe("done");
        expect(record?.summary).toBe("merged");
        expect(readFileSync(join(env.ctx.home, "journal", "2026-09.md"), "utf8")).toContain("closed `chief-cli` (done): merged");
    });

    test("--abandon marks abandoned", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await run("close", "chief-cli", "--abandon");
        expect((await loadRegistry(env.ctx))[0]?.state).toBe("abandoned");
    });
});

test("unknown commands and missing arguments are usage errors", async () => {
    env = testContext();
    await expect(run("bogus")).rejects.toThrow(/usage/i);
    await expect(run("status")).rejects.toThrow(/usage/i);
});
```

- [ ] **Step 2: Run to verify failure** — `bun test test/commands.test.ts` → FAIL, module not found.

- [ ] **Step 3: Implement**

`src/commands.ts`:

```ts
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import { type ParseArgsConfig, parseArgs } from "node:util";
import { ChiefError, type Context } from "./context";
import { appendJournal } from "./journal";
import { findSession, isActive, loadRegistry, type SessionRecord, updateSession } from "./registry";
import { minutesBetween } from "./time";

export interface CommandResult {
    output: string;
}

type Command = (ctx: Context, args: string[]) => Promise<CommandResult>;

const USAGE = `usage: chief <command> [options]

  init                                   create the state directory
  list [--all] [--json]                  sessions in flight
  status <session>                       one session's record
  note <text…>                           append to the journal
  close <session> [--abandon] [--summary <text>]`;

const json = (value: unknown): CommandResult => ({ output: JSON.stringify(value, null, 2) });

export const COMMANDS: Record<string, Command> = {
    init: async (ctx) => {
        await initHome(ctx);
        return { output: `Initialized ${ctx.home}` };
    },
    list: async (ctx, args) => {
        const { values } = parse(args, { all: { type: "boolean" }, json: { type: "boolean" } });
        const sessions = (await loadRegistry(ctx)).filter((s) => values.all || isActive(s));
        if (values.json) return json(sessions);
        if (sessions.length === 0) return { output: "No sessions in flight." };
        return { output: sessions.map((s) => describeLine(ctx, s)).join("\n") };
    },
    status: async (ctx, args) => json(await findSession(ctx, requirePositional(args, 0, "session"))),
    note: async (ctx, args) => {
        if (args.length === 0) throw usage("note needs text");
        await appendJournal(ctx, args.join(" "));
        return { output: "Noted." };
    },
    close: async (ctx, args) => {
        const { values, positionals } = parse(args, { abandon: { type: "boolean" }, summary: { type: "string" } });
        const state = values.abandon ? "abandoned" : "done";
        return json(await closeSession(ctx, requirePositional(positionals, 0, "session"), state, values.summary));
    },
};

export async function runCommand(ctx: Context, argv: string[]): Promise<CommandResult> {
    const [name, ...args] = argv;
    const command = name ? COMMANDS[name] : undefined;
    if (!command) throw usage(name ? `unknown command "${name}"` : "no command given");
    return command(ctx, args);
}

export async function initHome(ctx: Context): Promise<void> {
    await Promise.all(["journal", "hooks"].map((dir) => mkdir(join(ctx.home, dir), { recursive: true })));
}

export async function closeSession(
    ctx: Context,
    ref: string,
    state: "done" | "abandoned",
    summary?: string,
): Promise<SessionRecord> {
    const session = await findSession(ctx, ref);
    const closed = await updateSession(ctx, session.id, (s) => ({
        state,
        waiting_on: null,
        summary: summary ?? s.summary,
    }));
    await appendJournal(ctx, `closed \`${closed.slug}\` (${state})${summary ? `: ${summary}` : ""}`);
    return closed;
}

function describeLine(ctx: Context, s: SessionRecord): string {
    const detail = s.state === "waiting" ? `waiting on ${s.waiting_on}` : s.state;
    const idle = minutesBetween(s.last_activity_at, ctx.now());
    return `${s.slug.padEnd(20)} ${detail.padEnd(28)} ${s.harness}/${s.model}  idle ${idle}m  ${s.summary ?? ""}`.trimEnd();
}

type Options = NonNullable<ParseArgsConfig["options"]>;

export function parse<T extends Options>(args: string[], options: T) {
    try {
        return parseArgs({ args, options, allowPositionals: true, strict: true });
    } catch (error) {
        throw usage((error as Error).message);
    }
}

export function requirePositional(positionals: string[], index: number, name: string): string {
    const value = positionals[index];
    if (!value) throw usage(`missing <${name}>`);
    return value;
}

export function usage(problem: string): ChiefError {
    return new ChiefError(`${problem}\n\n${USAGE}`);
}
```

`src/cli.ts`:

```ts
#!/usr/bin/env bun
import { runCommand } from "./commands";
import { ChiefError, defaultContext } from "./context";

try {
    const { output } = await runCommand(defaultContext(), process.argv.slice(2));
    if (output) console.log(output);
} catch (error) {
    if (!(error instanceof ChiefError)) throw error;
    console.error(`chief: ${error.message}`);
    process.exit(1);
}
```

Then `chmod +x src/cli.ts`.

`install.sh` — add beside the other `~/.local/bin` links:

```bash
link_file "$CWD/ai/tools/chief-of-staff/src/cli.ts" "$HOME/.local/bin/chief"
```

`README.md` — what `chief` is (link to the design doc), `make install|specs|lint`,
the state directory layout, and the command list (copy `USAGE`). Keep it short;
each later task appends its commands.

- [ ] **Step 4: Run tests and lint** — `make specs && make lint` → PASS.

- [ ] **Step 5: Smoke test against a scratch home**

```bash
CHIEF_HOME=/tmp/chief-smoke ~/.config/ai/tools/chief-of-staff/src/cli.ts init
CHIEF_HOME=/tmp/chief-smoke ~/.config/ai/tools/chief-of-staff/src/cli.ts note hello
CHIEF_HOME=/tmp/chief-smoke ~/.config/ai/tools/chief-of-staff/src/cli.ts list
cat /tmp/chief-smoke/journal/*.md
```

Expected: `Initialized …`, `Noted.`, `No sessions in flight.`, and a journal with one bullet.

- [ ] **Step 6: Commit** — `Chief: Add CLI with init, list, status, note, close` (includes `install.sh`).

---

### Task 4: Worktree creation and kickoff prompt

**Files:**

- Create: `src/worktree.ts`, `src/kickoff.ts`
- Modify: `git/ignore` (append `.chief-kickoff.md`)
- Test: `test/worktree.test.ts`, `test/kickoff.test.ts`

**Interfaces:**

- Consumes: `Context`, `ChiefError`, `Autonomy`, `shellQuote`
- Produces:
    - `interface Worktree { repo: string; path: string; branch: string }`
    - `createWorktree(ctx, repoDir, slug): Promise<Worktree>` — path is `<worktreeRoot>/<repo basename>/<slug>`, branch is `<slug>`
    - `slugify(goal): string`, `validateSlug(slug): string`
    - `KICKOFF_FILE = ".chief-kickoff.md"`
    - `kickoffPrompt({ id, slug, goal, autonomy, chief }): string` where `chief` is the shell command that runs the CLI

- [ ] **Step 1: Write the failing tests**

`test/worktree.test.ts`:

```ts
import { afterEach, expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { basename, join } from "node:path";
import { realRunner } from "../src/context";
import { createWorktree } from "../src/worktree";
import { makeGitRepo, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

test("creates a branch and worktree under the worktree root, named for the repo", async () => {
    env = testContext();
    const repo = await makeGitRepo(env.root);
    const worktree = await createWorktree(env.ctx, repo, "fix-login");
    expect(worktree).toEqual({ repo, path: join(env.ctx.worktreeRoot, basename(repo), "fix-login"), branch: "fix-login" });
    expect(existsSync(worktree.path)).toBe(true);
    const branch = await realRunner(["git", "-C", worktree.path, "branch", "--show-current"]);
    expect(branch.stdout.trim()).toBe("fix-login");
});

test("resolves a subdirectory to the repository root", async () => {
    env = testContext();
    const repo = await makeGitRepo(env.root);
    await realRunner(["mkdir", "-p", join(repo, "sub")]);
    expect((await createWorktree(env.ctx, join(repo, "sub"), "x")).repo).toBe(repo);
});

test("fails clearly outside a git repository", async () => {
    env = testContext();
    await expect(createWorktree(env.ctx, env.root, "x")).rejects.toThrow(/not a git repository|rev-parse/i);
});

test("fails clearly when the branch already exists", async () => {
    env = testContext();
    const repo = await makeGitRepo(env.root);
    await createWorktree(env.ctx, repo, "dup");
    await expect(createWorktree(env.ctx, repo, "dup")).rejects.toThrow(/worktree add/);
});
```

`test/kickoff.test.ts`:

```ts
import { describe, expect, test } from "bun:test";
import { kickoffPrompt, slugify, validateSlug } from "../src/kickoff";

describe("slugify", () => {
    test("lowercases and hyphenates", () => {
        expect(slugify("Implement chief spawn + registry!")).toBe("implement-chief-spawn-registry");
    });
    test("caps length at 40 without a trailing hyphen", () => {
        const slug = slugify("a".repeat(39) + " bcd");
        expect(slug.length).toBeLessThanOrEqual(40);
        expect(slug.endsWith("-")).toBe(false);
    });
    test("rejects text with nothing usable", () => {
        expect(() => slugify("!!!")).toThrow(/--slug/);
    });
});

describe("validateSlug", () => {
    test("accepts a plain slug", () => expect(validateSlug("chief-cli")).toBe("chief-cli"));
    test.each(["../escape", "has space", "UPPER", "-leading", "a/b", ""])("rejects %p", (bad) => {
        expect(() => validateSlug(bad)).toThrow();
    });
});

describe("kickoffPrompt", () => {
    const base = { id: "0190-id", slug: "chief-cli", goal: "Build it", chief: "bun '/opt/chief/src/cli.ts'" };

    test("states the goal, the session id, and exact report commands", () => {
        const prompt = kickoffPrompt({ ...base, autonomy: "auto" });
        expect(prompt).toContain("Build it");
        expect(prompt).toContain("bun '/opt/chief/src/cli.ts' report 0190-id --state waiting --waiting-on");
        expect(prompt).toContain("bun '/opt/chief/src/cli.ts' report 0190-id --state done");
    });

    test("auto mode grants continue-without-prompting but keeps the always-escalate list", () => {
        const prompt = kickoffPrompt({ ...base, autonomy: "auto" });
        expect(prompt).toContain("continue without prompting");
        for (const item of ["push", "pull request", "destructive", "scope"]) expect(prompt).toContain(item);
    });

    test("checkpointed mode adds checkpoints after the plan and the tests", () => {
        const prompt = kickoffPrompt({ ...base, autonomy: "checkpointed" });
        expect(prompt).toContain("approve-plan");
        expect(prompt).toContain("approve-tests");
    });
});
```

- [ ] **Step 2: Run to verify failure** — FAIL, modules not found.

- [ ] **Step 3: Implement**

`src/worktree.ts`:

```ts
import { basename, join } from "node:path";
import { ChiefError, type Context } from "./context";

export interface Worktree {
    repo: string;
    path: string;
    branch: string;
}

export async function createWorktree(ctx: Context, repoDir: string, slug: string): Promise<Worktree> {
    const repo = await git(ctx, ["-C", repoDir, "rev-parse", "--show-toplevel"]);
    const path = join(ctx.worktreeRoot, basename(repo), slug);
    await git(ctx, ["-C", repo, "worktree", "add", "-b", slug, path]);
    return { repo, path, branch: slug };
}

async function git(ctx: Context, args: string[]): Promise<string> {
    const result = await ctx.run(["git", ...args]);
    if (result.exitCode !== 0) throw new ChiefError(`git ${args.slice(2).join(" ")} failed: ${result.stderr.trim()}`);
    return result.stdout.trim();
}
```

`src/kickoff.ts`:

```ts
import { ChiefError } from "./context";
import type { Autonomy } from "./registry";

export const KICKOFF_FILE = ".chief-kickoff.md";
const MAX_SLUG = 40;
// Becomes a branch name and a path segment: no slashes, dots, or leading hyphen.
const SLUG = /^[a-z0-9][a-z0-9-]{0,39}$/;

export function slugify(goal: string): string {
    const slug = goal.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, MAX_SLUG).replace(/^-+|-+$/g, "");
    if (!slug) throw new ChiefError(`cannot derive a slug from "${goal}"; pass --slug`);
    return slug;
}

export function validateSlug(slug: string): string {
    if (!SLUG.test(slug)) throw new ChiefError(`invalid slug "${slug}": use lowercase letters, digits, and hyphens`);
    return slug;
}

export interface KickoffInput {
    id: string;
    slug: string;
    goal: string;
    autonomy: Autonomy;
    chief: string; // shell command that runs the chief CLI
}

export function kickoffPrompt({ id, slug, goal, autonomy, chief }: KickoffInput): string {
    const report = `${chief} report ${id}`;
    return `# Chief of Staff kickoff: ${slug}

You are a worker session spawned by the Chief of Staff. Session id: \`${id}\`.

## Goal

${goal}

## How to work

You are in a dedicated git worktree on branch \`${slug}\`. Follow the repository's
AGENTS.md / CLAUDE.md for workflow, testing, linting, reviews, and commit style.

The human has authorized you to **continue without prompting**, as defined in
AGENTS.md, **except** for the items under "Always escalate". Commit locally as you go.

${autonomy === "checkpointed" ? CHECKPOINTS(report) : ""}## Always escalate

Stop and report \`waiting\` before any of these. Do not do them yourself.

- Test and spec design for non-trivial work (\`--waiting-on approve-tests\`)
- git push, or opening a pull request (\`--waiting-on approve-push\`)
- Any destructive operation: deleting files outside this task, rewriting history, dropping data (\`--waiting-on approve-destructive\`)
- A change of scope from the goal above (\`--waiting-on approve-scope\`)

## Reporting status

Report with these exact commands, then end your turn:

- Need a human decision: \`${report} --state waiting --waiting-on <checkpoint> --summary "<one line>"\`
- Blocked by something outside your control: \`${report} --state blocked --summary "<what and why>"\`
- Finished: \`${report} --state done --summary "<what changed; branch ${slug}>"\`

If you stop without reporting, Chief assumes you are waiting on the human.
`;
}

const CHECKPOINTS = (report: string) => `## Checkpoints

This session is **checkpointed**. Also stop and report \`waiting\` at each of these:

1. After writing a plan, before any code: \`${report} --state waiting --waiting-on approve-plan --summary "<plan in one line>"\`
2. After writing tests, before implementing: \`${report} --state waiting --waiting-on approve-tests --summary "<what the tests specify>"\`

`;
```

`git/ignore` — append:

```text
# Chief of Staff writes each worker's instructions into its worktree root.
.chief-kickoff.md
```

- [ ] **Step 4: Run tests and lint** — PASS.
- [ ] **Step 5: Commit** — `Chief: Add worktree creation and worker kickoff prompt` (include `git/ignore`).

---

### Task 5: Claude harness adapter

Pure functions only; every Claude-specific string lives here.

**Files:**

- Create: `src/harness/claude.ts`
- Create: `test/fixtures/claude-transcript.jsonl`
- Test: `test/harness-claude.test.ts`

**Interfaces:**

- Consumes: `KICKOFF_FILE`, `shellQuote`
- Produces:
    - `launchArgv({ id, slug, model, effort, settingsPath }): string[]`
    - `resumeArgv(id, message): string[]`
    - `parseBgRef(stdout): string | null` — the short id `claude attach` takes
    - `stopHookSettings(command): object`
    - `attachCommands(id, ref, worktree): { terminal: string | null; resume: string }`
    - `transcriptPath(claudeHome, worktree, id): string`
    - `interface TranscriptDigest { lastActivityAt: string | null; textMessages: number; toolCalls: number; recentMessages: string[] }`
    - `digestTranscript(jsonl, recent?): TranscriptDigest`

- [ ] **Step 1: Write the synthetic transcript fixture**

`test/fixtures/claude-transcript.jsonl` (one JSON object per line; shape matches real transcripts, content is invented):

```text
{"type":"agent-name","sessionId":"s"}
{"type":"user","timestamp":"2026-09-23T14:02:05.000Z","message":{"role":"user","content":"Read .chief-kickoff.md"}}
{"type":"assistant","timestamp":"2026-09-23T14:02:10.000Z","message":{"role":"assistant","content":[{"type":"thinking","thinking":"hmm"}]}}
{"type":"assistant","timestamp":"2026-09-23T14:02:11.000Z","message":{"role":"assistant","content":[{"type":"tool_use","name":"Read","input":{}}]}}
{"type":"assistant","timestamp":"2026-09-23T14:05:00.000Z","message":{"role":"assistant","content":[{"type":"text","text":"Wrote the registry tests."}]}}
{"type":"attachment","timestamp":"2026-09-23T14:06:00.000Z"}
{"type":"assistant","timestamp":"2026-09-23T14:40:00.000Z","message":{"role":"assistant","content":[{"type":"tool_use","name":"Bash","input":{}},{"type":"text","text":"Tests written; waiting for review."}]}}
{"type":"assistant","timestamp":"2026-09-23T14:41:0
```

The last line is deliberately truncated: a transcript being written can end mid-line.

- [ ] **Step 2: Write the failing tests**

`test/harness-claude.test.ts`:

```ts
import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
    attachCommands,
    digestTranscript,
    launchArgv,
    parseBgRef,
    resumeArgv,
    stopHookSettings,
    transcriptPath,
} from "../src/harness/claude";

const fixture = (name: string) => readFileSync(join(import.meta.dir, "fixtures", name), "utf8");

test("launchArgv starts a named background session with our id, model, effort, and hooks", () => {
    expect(launchArgv({ id: "U", slug: "s", model: "opus", effort: "high", settingsPath: "/h.json" })).toEqual([
        "claude", "--bg", "--session-id", "U", "--name", "s", "--model", "opus", "--effort", "high",
        "--permission-mode", "auto", "--settings", "/h.json",
        "Read .chief-kickoff.md in the current directory and follow it.",
    ]);
});

test("resumeArgv continues the same session in the background", () => {
    expect(resumeArgv("U", "Approved.")).toEqual(["claude", "--bg", "--resume", "U", "Approved."]);
});

describe("parseBgRef", () => {
    test("reads the short id from real `claude --bg` output (spike fixture)", () => {
        expect(parseBgRef(fixture("claude-bg-output.txt"))).toMatch(/^\S+$/);
    });
    test("returns null when the output has no id", () => {
        expect(parseBgRef("something unexpected")).toBeNull();
    });
});

test("stopHookSettings registers one Stop command", () => {
    expect(stopHookSettings("chief report U --stopped")).toEqual({
        hooks: { Stop: [{ hooks: [{ type: "command", command: "chief report U --stopped", timeout: 30 }] }] },
    });
});

test("attachCommands offers attach only when a short id is known", () => {
    expect(attachCommands("U", "ab12", "/w t")).toEqual({ terminal: "claude attach ab12", resume: "cd '/w t' && claude --resume U" });
    expect(attachCommands("U", null, "/w").terminal).toBeNull();
});

test("transcriptPath mirrors Claude's project-directory naming", () => {
    expect(transcriptPath("/c", "/Users/me/.local/share/claude/worktrees/.config/x", "U")).toBe(
        "/c/projects/-Users-me--local-share-claude-worktrees--config-x/U.jsonl",
    );
});

describe("digestTranscript", () => {
    const digest = digestTranscript(fixture("claude-transcript.jsonl"), 2);

    test("takes last activity from user and assistant entries only", () => {
        expect(digest.lastActivityAt).toBe("2026-09-23T14:40:00.000Z");
    });
    test("counts tool calls and text messages", () => {
        expect(digest.toolCalls).toBe(2);
        expect(digest.textMessages).toBe(2);
    });
    test("keeps the most recent text messages, oldest first", () => {
        expect(digest.recentMessages).toEqual(["Wrote the registry tests.", "Tests written; waiting for review."]);
    });
    test("an empty transcript has no activity", () => {
        expect(digestTranscript("")).toEqual({ lastActivityAt: null, textMessages: 0, toolCalls: 0, recentMessages: [] });
    });
});
```

- [ ] **Step 3: Run to verify failure** — FAIL, module not found.

- [ ] **Step 4: Implement `src/harness/claude.ts`**

```ts
import { join } from "node:path";
import { KICKOFF_FILE } from "../kickoff";
import { shellQuote } from "../text";

const KICKOFF_INSTRUCTION = `Read ${KICKOFF_FILE} in the current directory and follow it.`;
const HOOK_TIMEOUT_SECONDS = 30;

export interface LaunchSpec {
    id: string;
    slug: string;
    model: string;
    effort: string;
    settingsPath: string;
}

export function launchArgv({ id, slug, model, effort, settingsPath }: LaunchSpec): string[] {
    return [
        "claude", "--bg", "--session-id", id, "--name", slug, "--model", model, "--effort", effort,
        "--permission-mode", "auto", "--settings", settingsPath, KICKOFF_INSTRUCTION,
    ];
}

export function resumeArgv(id: string, message: string): string[] {
    return ["claude", "--bg", "--resume", id, message];
}

// Shape confirmed by the Task 0 spike; see docs/spike-notes.md. Adjust these patterns
// to the fixture if the spike showed a different format.
export function parseBgRef(stdout: string): string | null {
    const match = stdout.match(/claude attach (\S+)/) ?? stdout.match(/^\s*(?:id|session)\s*[:=]\s*(\S+)/im);
    return match?.[1] ?? null;
}

export function stopHookSettings(command: string) {
    return { hooks: { Stop: [{ hooks: [{ type: "command", command, timeout: HOOK_TIMEOUT_SECONDS }] }] } };
}

export function attachCommands(id: string, ref: string | null, worktree: string) {
    return {
        terminal: ref ? `claude attach ${ref}` : null,
        resume: `cd ${shellQuote(worktree)} && claude --resume ${id}`,
    };
}

export function transcriptPath(claudeHome: string, worktree: string, id: string): string {
    return join(claudeHome, "projects", worktree.replace(/[^a-zA-Z0-9]/g, "-"), `${id}.jsonl`);
}

export interface TranscriptDigest {
    lastActivityAt: string | null;
    textMessages: number;
    toolCalls: number;
    recentMessages: string[];
}

// Transcript entries are external JSON; type only what we read, and narrow before use.
interface TranscriptEntry {
    type?: unknown;
    timestamp?: unknown;
    message?: { content?: unknown };
}

interface ContentBlock {
    type?: string;
    text?: string;
}

export function digestTranscript(jsonl: string, recent = 3): TranscriptDigest {
    let lastActivityAt: string | null = null;
    let toolCalls = 0;
    const texts: string[] = [];
    for (const entry of parseLines(jsonl)) {
        if (entry.type !== "user" && entry.type !== "assistant") continue;
        if (typeof entry.timestamp === "string") lastActivityAt = entry.timestamp;
        if (entry.type !== "assistant" || !Array.isArray(entry.message?.content)) continue;
        for (const block of entry.message.content as ContentBlock[]) {
            if (block.type === "tool_use") toolCalls++;
            if (block.type === "text" && block.text?.trim()) texts.push(block.text.trim());
        }
    }
    return { lastActivityAt, textMessages: texts.length, toolCalls, recentMessages: texts.slice(-recent) };
}

// A transcript being written can end mid-line; skip what does not parse.
function parseLines(jsonl: string): TranscriptEntry[] {
    return jsonl.split("\n").flatMap((line) => {
        if (!line.trim()) return [];
        try {
            return [JSON.parse(line) as TranscriptEntry];
        } catch {
            return [];
        }
    });
}
```

- [ ] **Step 5: Run tests and lint** — PASS.
- [ ] **Step 6: Commit** — `Chief: Add Claude harness adapter`

---

### Task 6: `chief spawn` (Claude only)

**Files:**

- Create: `src/spawn.ts`
- Modify: `src/commands.ts` (add `spawn` to `COMMANDS` and `USAGE`)
- Test: `test/spawn.test.ts`

**Interfaces:**

- Consumes: `createWorktree`, `kickoffPrompt`, `slugify`, `validateSlug`, `KICKOFF_FILE`, `launchArgv`, `parseBgRef`, `stopHookSettings`, `attachCommands`, `addSession`, `loadRegistry`, `isActive`, `appendJournal`
- Produces:
    - `interface SpawnOptions { goal: string; slug?: string; repo: string; harness: Harness; model: string; effort: string; autonomy: Autonomy }`
    - `spawnSession(ctx, options): Promise<SessionRecord>`
    - `chiefCommand(ctx): string` — `bun '<cliPath>'`, used in hook settings and the kickoff prompt

- [ ] **Step 1: Write the failing tests**

`test/spawn.test.ts`:

```ts
import { afterEach, describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { runCommand } from "../src/commands";
import { KICKOFF_FILE } from "../src/kickoff";
import { addSession, loadRegistry } from "../src/registry";
import { type SpawnOptions, spawnSession } from "../src/spawn";
import { makeGitRepo, sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const BG_OUTPUT = readFileSync(join(import.meta.dir, "fixtures", "claude-bg-output.txt"), "utf8");
const UUID_V7 = /^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

async function spawnDefault(overrides: Partial<SpawnOptions> = {}) {
    const repo = await makeGitRepo(env.root);
    const record = await spawnSession(env.ctx, {
        goal: "Fix the login bug",
        repo,
        harness: "claude",
        model: "opus",
        effort: "high",
        autonomy: "auto",
        ...overrides,
    });
    return { repo, record };
}

describe("spawnSession", () => {
    test("records a running session with a UUIDv7 id and a worktree", async () => {
        env = testContext({ fakes: { claude: { stdout: BG_OUTPUT } } });
        const { repo, record } = await spawnDefault();
        expect(record.id).toMatch(UUID_V7);
        expect(record).toMatchObject({
            slug: "fix-the-login-bug",
            branch: "fix-the-login-bug",
            repo,
            worktree: join(env.ctx.worktreeRoot, "repo", "fix-the-login-bug"),
            state: "running",
            spawned_at: "2026-09-23T14:02:00.000Z",
        });
        expect(record.harness_ref).not.toBeNull();
        expect(await loadRegistry(env.ctx)).toEqual([record]);
    });

    test("writes the kickoff prompt into the worktree", async () => {
        env = testContext({ fakes: { claude: { stdout: BG_OUTPUT } } });
        const { record } = await spawnDefault();
        const prompt = readFileSync(join(record.worktree, KICKOFF_FILE), "utf8");
        expect(prompt).toContain("Fix the login bug");
        expect(prompt).toContain(`bun '/opt/chief/src/cli.ts' report ${record.id}`);
    });

    test("launches claude in the worktree with a Stop hook that reports back", async () => {
        env = testContext({ fakes: { claude: { stdout: BG_OUTPUT } } });
        const { record } = await spawnDefault();
        const [call] = env.calls;
        expect(call?.cwd).toBe(record.worktree);
        expect(call?.argv.slice(0, 4)).toEqual(["claude", "--bg", "--session-id", record.id]);
        const settingsPath = call?.argv[call.argv.indexOf("--settings") + 1] ?? "";
        const settings = JSON.parse(readFileSync(settingsPath, "utf8"));
        expect(settings.hooks.Stop[0].hooks[0].command).toBe(`bun '/opt/chief/src/cli.ts' report ${record.id} --stopped`);
    });

    test("journals the spawn", async () => {
        env = testContext({ fakes: { claude: { stdout: BG_OUTPUT } } });
        await spawnDefault();
        expect(readFileSync(join(env.ctx.home, "journal", "2026-09.md"), "utf8")).toContain(
            "spawned `fix-the-login-bug` (claude/opus/high, auto) — goal: Fix the login bug",
        );
    });

    test("records a failed launch as blocked instead of losing it", async () => {
        env = testContext({ fakes: { claude: { exitCode: 1, stderr: "error: not logged in\nmore" } } });
        const { record } = await spawnDefault();
        expect(record.state).toBe("blocked");
        expect(record.summary).toBe("launch failed: error: not logged in");
    });

    test("uses an explicit --slug after validating it", async () => {
        env = testContext({ fakes: { claude: { stdout: BG_OUTPUT } } });
        expect((await spawnDefault({ slug: "login" })).record.slug).toBe("login");
        await expect(spawnDefault({ slug: "../evil" })).rejects.toThrow(/invalid slug/);
    });

    test("refuses a slug already used by an active session", async () => {
        env = testContext({ fakes: { claude: { stdout: BG_OUTPUT } } });
        await addSession(env.ctx, sampleRecord({ slug: "login" }));
        await expect(spawnDefault({ slug: "login" })).rejects.toThrow(/already in use/);
    });

    test("refuses harnesses not supported yet", async () => {
        env = testContext();
        await expect(spawnDefault({ harness: "codex" })).rejects.toThrow(/not supported yet/);
    });
});

test("the spawn command applies defaults: claude, opus, high, auto", async () => {
    env = testContext({ fakes: { claude: { stdout: BG_OUTPUT } } });
    const repo = await makeGitRepo(env.root);
    const { output } = await runCommand(env.ctx, ["spawn", "--goal", "Fix it", "--repo", repo]);
    expect(JSON.parse(output)).toMatchObject({ harness: "claude", model: "opus", effort: "high", autonomy: "auto" });
});

test("the spawn command rejects an unknown --autonomy", async () => {
    env = testContext();
    await expect(runCommand(env.ctx, ["spawn", "--goal", "x", "--autonomy", "yolo"])).rejects.toThrow(/autonomy/);
});
```

- [ ] **Step 2: Run to verify failure** — FAIL.

- [ ] **Step 3: Implement `src/spawn.ts`**

```ts
import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { ChiefError, type Context } from "./context";
import { attachCommands, launchArgv, parseBgRef, stopHookSettings } from "./harness/claude";
import { appendJournal } from "./journal";
import { KICKOFF_FILE, kickoffPrompt, slugify, validateSlug } from "./kickoff";
import { addSession, type Autonomy, type Harness, isActive, loadRegistry, type SessionRecord } from "./registry";
import { firstLine, shellQuote } from "./text";
import { createWorktree } from "./worktree";

export interface SpawnOptions {
    goal: string;
    slug?: string;
    repo: string;
    harness: Harness;
    model: string;
    effort: string;
    autonomy: Autonomy;
}

export function chiefCommand(ctx: Context): string {
    return `bun ${shellQuote(ctx.cliPath)}`;
}

export async function spawnSession(ctx: Context, options: SpawnOptions): Promise<SessionRecord> {
    const { goal, harness, model, effort, autonomy } = options;
    if (harness !== "claude") throw new ChiefError(`harness "${harness}" is not supported yet`);
    const slug = options.slug ? validateSlug(options.slug) : slugify(goal);
    await ensureSlugAvailable(ctx, slug);

    const worktree = await createWorktree(ctx, options.repo, slug);
    const id = Bun.randomUUIDv7();
    await writeFile(join(worktree.path, KICKOFF_FILE), kickoffPrompt({ id, slug, goal, autonomy, chief: chiefCommand(ctx) }));
    const settingsPath = await writeStopHook(ctx, id);
    const launch = await ctx.run(launchArgv({ id, slug, model, effort, settingsPath }), { cwd: worktree.path });
    const launched = launch.exitCode === 0;
    const harnessRef = launched ? parseBgRef(launch.stdout) : null;

    const now = ctx.now().toISOString();
    const record: SessionRecord = {
        id,
        slug,
        goal,
        harness,
        harness_ref: harnessRef,
        model,
        effort,
        repo: worktree.repo,
        worktree: worktree.path,
        branch: worktree.branch,
        autonomy,
        state: launched ? "running" : "blocked",
        waiting_on: null,
        summary: launched ? null : `launch failed: ${firstLine(launch.stderr)}`,
        cross_check: null,
        spawned_at: now,
        last_activity_at: now,
        attach: attachCommands(id, harnessRef, worktree.path),
    };
    await addSession(ctx, record);
    await appendJournal(
        ctx,
        `spawned \`${slug}\` (${harness}/${model}/${effort}, ${autonomy}) — goal: ${goal}${launched ? "" : " — LAUNCH FAILED"}`,
    );
    return record;
}

async function ensureSlugAvailable(ctx: Context, slug: string): Promise<void> {
    const clash = (await loadRegistry(ctx)).find((s) => s.slug === slug && isActive(s));
    if (clash) throw new ChiefError(`slug "${slug}" is already in use by an active session (${clash.id})`);
}

async function writeStopHook(ctx: Context, id: string): Promise<string> {
    const dir = join(ctx.home, "hooks");
    await mkdir(dir, { recursive: true });
    const path = join(dir, `${id}.json`);
    const settings = stopHookSettings(`${chiefCommand(ctx)} report ${id} --stopped`);
    await writeFile(path, `${JSON.stringify(settings, null, 2)}\n`);
    return path;
}
```

- [ ] **Step 4: Register the command in `src/commands.ts`**

Imports: `spawnSession` from `./spawn`; add `AUTONOMIES`, `HARNESSES` to the `./registry` import.

Add to `COMMANDS`:

```ts
    spawn: async (ctx, args) => {
        const { values } = parse(args, {
            goal: { type: "string" },
            slug: { type: "string" },
            repo: { type: "string", default: process.cwd() },
            harness: { type: "string", default: "claude" },
            model: { type: "string", default: "opus" },
            effort: { type: "string", default: "high" },
            autonomy: { type: "string", default: "auto" },
        });
        if (!values.goal) throw usage("spawn needs --goal");
        return json(
            await spawnSession(ctx, {
                goal: values.goal,
                slug: values.slug,
                repo: values.repo,
                harness: oneOf(HARNESSES, values.harness, "harness"),
                model: values.model,
                effort: values.effort,
                autonomy: oneOf(AUTONOMIES, values.autonomy, "autonomy"),
            }),
        );
    },
```

Add the helper (used again by `report` in Task 7):

```ts
export function oneOf<T extends string>(allowed: readonly T[], value: string, name: string): T {
    if (!(allowed as readonly string[]).includes(value)) throw usage(`--${name} must be one of: ${allowed.join(", ")}`);
    return value as T;
}
```

Add to `USAGE`:

```text
  spawn --goal <text> [--slug s] [--repo dir] [--model m] [--effort e] [--autonomy auto|checkpointed]
```

- [ ] **Step 5: Run tests and lint** — PASS.

- [ ] **Step 6: Live check (one real worker)**

```bash
chief spawn --goal "Create HELLO.txt containing hello, then report done" --slug chief-live-check --model sonnet --effort low --repo ~/.config
chief list
```

Expected: `chief-live-check` running; within a minute or two `chief list` shows it
`done` (Task 7 must land first for the report to be accepted; if running this now,
expect the hook to error harmlessly). Clean up with `claude rm <ref>`,
`git -C ~/.config worktree remove --force <worktree>`, `git -C ~/.config branch -D chief-live-check`,
and `chief close chief-live-check --abandon`.

- [ ] **Step 7: Commit** — `Chief: Add spawn for Claude workers`

---

### Task 7: `chief report` — explicit and Stop-hook modes

**Files:**

- Create: `src/report.ts`
- Modify: `src/commands.ts`, `src/cli.ts`
- Test: `test/report.test.ts`

**Interfaces:**

- Consumes: `findSession`, `updateSession`, `appendJournal`, `STATES`, `oneOf`
- Produces:
    - `reportState(ctx, ref, { state, waitingOn?, summary? }): Promise<SessionRecord>`
    - `reportStopped(ctx, ref, hookInput: string): Promise<SessionRecord | null>`
    - `UNREPORTED_STOP = "unreported-stop"`

- [ ] **Step 1: Write the failing tests**

`test/report.test.ts`:

```ts
import { afterEach, describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { runCommand } from "../src/commands";
import { addSession, loadRegistry } from "../src/registry";
import { reportState, reportStopped } from "../src/report";
import { sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const journal = () => readFileSync(join(env.ctx.home, "journal", "2026-09.md"), "utf8");
const stored = async () => (await loadRegistry(env.ctx))[0];

describe("reportState", () => {
    test("waiting records the checkpoint, summary, and activity time, and journals it", async () => {
        env = testContext({ now: "2026-09-23T14:40:00Z" });
        await addSession(env.ctx, sampleRecord());
        await reportState(env.ctx, "chief-cli", { state: "waiting", waitingOn: "approve-tests", summary: "tests written" });
        expect(await stored()).toMatchObject({
            state: "waiting",
            waiting_on: "approve-tests",
            summary: "tests written",
            last_activity_at: "2026-09-23T14:40:00.000Z",
        });
        expect(journal()).toContain("- 14:40 `chief-cli` waiting on approve-tests: tests written");
    });

    test("waiting requires a checkpoint name", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await expect(reportState(env.ctx, "chief-cli", { state: "waiting" })).rejects.toThrow(/--waiting-on/);
    });

    test("leaving waiting clears waiting_on and keeps the old summary if none is given", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ state: "waiting", waiting_on: "x", summary: "kept" }));
        await reportState(env.ctx, "chief-cli", { state: "running" });
        expect(await stored()).toMatchObject({ state: "running", waiting_on: null, summary: "kept" });
    });
});

describe("reportStopped (Stop hook)", () => {
    test("a stop while still running means the worker is waiting on the human", async () => {
        env = testContext({ now: "2026-09-23T15:00:00Z" });
        await addSession(env.ctx, sampleRecord());
        await reportStopped(env.ctx, "chief-cli", JSON.stringify({ last_assistant_message: "Which DB should I use?\nThanks" }));
        expect(await stored()).toMatchObject({
            state: "waiting",
            waiting_on: "unreported-stop",
            summary: "Which DB should I use? Thanks",
            last_activity_at: "2026-09-23T15:00:00.000Z",
        });
        expect(journal()).toContain("`chief-cli` stopped without reporting");
    });

    test("after an explicit report, a stop only refreshes activity", async () => {
        env = testContext({ now: "2026-09-23T15:00:00Z" });
        await addSession(env.ctx, sampleRecord({ state: "done", summary: "merged" }));
        await reportStopped(env.ctx, "chief-cli", "{}");
        expect(await stored()).toMatchObject({ state: "done", summary: "merged", last_activity_at: "2026-09-23T15:00:00.000Z" });
    });

    test("ignores re-entrant stops", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        expect(await reportStopped(env.ctx, "chief-cli", JSON.stringify({ stop_hook_active: true }))).toBeNull();
        expect((await stored())?.state).toBe("running");
    });

    test("tolerates malformed hook input", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await reportStopped(env.ctx, "chief-cli", "not json");
        expect((await stored())?.state).toBe("waiting");
    });

    test("truncates a long last message", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await reportStopped(env.ctx, "chief-cli", JSON.stringify({ last_assistant_message: "x".repeat(500) }));
        expect((await stored())?.summary?.length).toBe(200);
    });
});

describe("report command", () => {
    test("explicit mode parses flags", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await runCommand(env.ctx, ["report", "chief-cli", "--state", "done", "--summary", "shipped"]);
        expect(await stored()).toMatchObject({ state: "done", summary: "shipped" });
    });

    test("--stopped reads hook input from stdin", async () => {
        env = testContext({ stdin: JSON.stringify({ last_assistant_message: "hi" }) });
        await addSession(env.ctx, sampleRecord());
        await runCommand(env.ctx, ["report", "chief-cli", "--stopped"]);
        expect((await stored())?.summary).toBe("hi");
    });

    test("rejects an unknown state", async () => {
        env = testContext();
        await expect(runCommand(env.ctx, ["report", "x", "--state", "napping"])).rejects.toThrow(/--state must be one of/);
    });
});
```

- [ ] **Step 2: Run to verify failure** — FAIL.

- [ ] **Step 3: Implement `src/report.ts`**

```ts
import { ChiefError, type Context } from "./context";
import { appendJournal } from "./journal";
import { findSession, type SessionRecord, type SessionState, updateSession } from "./registry";
import { oneLine, truncate } from "./text";

export const UNREPORTED_STOP = "unreported-stop";
const MAX_SUMMARY = 200;

export interface Report {
    state: SessionState;
    waitingOn?: string;
    summary?: string;
}

export async function reportState(ctx: Context, ref: string, { state, waitingOn, summary }: Report): Promise<SessionRecord> {
    if (state === "waiting" && !waitingOn) throw new ChiefError("--state waiting needs --waiting-on <checkpoint>");
    const session = await findSession(ctx, ref);
    const updated = await updateSession(ctx, session.id, (s) => ({
        state,
        waiting_on: state === "waiting" ? (waitingOn ?? null) : null,
        summary: summary ?? s.summary,
        last_activity_at: ctx.now().toISOString(),
    }));
    const detail = updated.waiting_on ? `${state} on ${updated.waiting_on}` : state;
    await appendJournal(ctx, `\`${updated.slug}\` ${detail}${summary ? `: ${summary}` : ""}`);
    return updated;
}

// Called by the worker's Stop hook after every turn. A worker that stops while still
// `running` never said why, so it needs a human look.
export async function reportStopped(ctx: Context, ref: string, hookInput: string): Promise<SessionRecord | null> {
    const input = parseHookInput(hookInput);
    if (input.stop_hook_active === true) return null;
    const session = await findSession(ctx, ref);
    const now = ctx.now().toISOString();
    const lastMessage = typeof input.last_assistant_message === "string" ? input.last_assistant_message : null;
    let unreported = false;
    const updated = await updateSession(ctx, session.id, (s) => {
        if (s.state !== "running") return { last_activity_at: now };
        unreported = true;
        return {
            state: "waiting",
            waiting_on: UNREPORTED_STOP,
            summary: lastMessage ? truncate(oneLine(lastMessage), MAX_SUMMARY) : s.summary,
            last_activity_at: now,
        };
    });
    if (unreported) await appendJournal(ctx, `\`${updated.slug}\` stopped without reporting; treating as waiting`);
    return updated;
}

function parseHookInput(text: string): Record<string, unknown> {
    try {
        const parsed = JSON.parse(text);
        return parsed && typeof parsed === "object" ? parsed : {};
    } catch {
        return {};
    }
}
```

- [ ] **Step 4: Register the command**

In `src/commands.ts` (imports: `reportState`, `reportStopped` from `./report`; `STATES` from `./registry`), add to `COMMANDS`:

```ts
    report: async (ctx, args) => {
        const { values, positionals } = parse(args, {
            state: { type: "string" },
            "waiting-on": { type: "string" },
            summary: { type: "string" },
            stopped: { type: "boolean" },
        });
        const ref = requirePositional(positionals, 0, "session");
        if (values.stopped) return json(await reportStopped(ctx, ref, await ctx.stdin()));
        if (!values.state) throw usage("report needs --state or --stopped");
        return json(
            await reportState(ctx, ref, {
                state: oneOf(STATES, values.state, "state"),
                waitingOn: values["waiting-on"],
                summary: values.summary,
            }),
        );
    },
```

And to `USAGE`:

```text
  report <session> --state <state> [--waiting-on <checkpoint>] [--summary <text>]
  report <session> --stopped             (Stop hook; reads hook JSON on stdin)
```

In `src/cli.ts`, a Stop hook must never fail the worker's turn. Replace the body with:

```ts
#!/usr/bin/env bun
import { runCommand } from "./commands";
import { ChiefError, defaultContext } from "./context";

const argv = process.argv.slice(2);
// A Stop hook must never break the worker it runs in: report problems, exit 0.
const isStopHook = argv[0] === "report" && argv.includes("--stopped");

try {
    const { output } = await runCommand(defaultContext(), argv);
    if (output && !isStopHook) console.log(output);
} catch (error) {
    if (!(error instanceof ChiefError) && !isStopHook) throw error;
    console.error(`chief: ${(error as Error).message}`);
    process.exit(isStopHook ? 0 : 1);
}
```

Stop-hook output is suppressed because Claude treats hook stdout as possible
control JSON.

- [ ] **Step 5: Run tests and lint** — PASS.
- [ ] **Step 6: Re-run Task 6 Step 6's live check** and confirm the worker ends `done`, with a journal line from its own `chief report`.
- [ ] **Step 7: Commit** — `Chief: Add report for worker status (push path)`

---

### Task 8: `chief approve` — release a waiting worker

**Files:**

- Create: `src/approve.ts`
- Modify: `src/commands.ts`
- Test: `test/approve.test.ts`

**Interfaces:**

- Consumes: `findSession`, `updateSession`, `appendJournal`, `resumeArgv`, `firstLine`
- Produces: `approveSession(ctx, ref, message?): Promise<SessionRecord>`, `DEFAULT_APPROVAL`

- [ ] **Step 1: Write the failing tests**

`test/approve.test.ts`:

```ts
import { afterEach, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { approveSession } from "../src/approve";
import { runCommand } from "../src/commands";
import { addSession, loadRegistry } from "../src/registry";
import { sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const waiting = sampleRecord({ state: "waiting", waiting_on: "approve-tests" });

test("resumes the same session in the background with the message, in its worktree", async () => {
    env = testContext();
    await addSession(env.ctx, waiting);
    await approveSession(env.ctx, "chief-cli", "Tests look good; implement.");
    expect(env.calls).toEqual([
        { argv: ["claude", "--bg", "--resume", waiting.id, "Tests look good; implement."], cwd: waiting.worktree },
    ]);
});

test("flips the worker back to running and journals what was released", async () => {
    env = testContext();
    await addSession(env.ctx, waiting);
    await approveSession(env.ctx, "chief-cli");
    expect((await loadRegistry(env.ctx))[0]).toMatchObject({ state: "running", waiting_on: null });
    expect(readFileSync(join(env.ctx.home, "journal", "2026-09.md"), "utf8")).toContain(
        "released `chief-cli` (was waiting on approve-tests): Approved. Continue.",
    );
});

test("refuses a session that is not waiting or blocked", async () => {
    env = testContext();
    await addSession(env.ctx, sampleRecord({ state: "running" }));
    await expect(approveSession(env.ctx, "chief-cli")).rejects.toThrow(/not waiting/);
    expect(env.calls).toEqual([]);
});

test("leaves the record untouched when the resume fails", async () => {
    env = testContext({ fakes: { claude: { exitCode: 1, stderr: "no such session" } } });
    await addSession(env.ctx, waiting);
    await expect(approveSession(env.ctx, "chief-cli")).rejects.toThrow(/no such session/);
    expect((await loadRegistry(env.ctx))[0]?.state).toBe("waiting");
});

test("the approve command joins remaining words into the message", async () => {
    env = testContext();
    await addSession(env.ctx, waiting);
    await runCommand(env.ctx, ["approve", "chief-cli", "ship", "it"]);
    expect(env.calls[0]?.argv.at(-1)).toBe("ship it");
});
```

- [ ] **Step 2: Run to verify failure** — FAIL.

- [ ] **Step 3: Implement `src/approve.ts`**

```ts
import { ChiefError, type Context } from "./context";
import { resumeArgv } from "./harness/claude";
import { appendJournal } from "./journal";
import { findSession, type SessionRecord, updateSession } from "./registry";
import { firstLine } from "./text";

export const DEFAULT_APPROVAL = "Approved. Continue.";

export async function approveSession(ctx: Context, ref: string, message = DEFAULT_APPROVAL): Promise<SessionRecord> {
    const session = await findSession(ctx, ref);
    if (session.state !== "waiting" && session.state !== "blocked") {
        throw new ChiefError(`\`${session.slug}\` is ${session.state}, not waiting`);
    }
    if (session.harness !== "claude") throw new ChiefError(`approve is not supported for ${session.harness} yet`);
    const result = await ctx.run(resumeArgv(session.id, message), { cwd: session.worktree });
    if (result.exitCode !== 0) throw new ChiefError(`could not resume \`${session.slug}\`: ${firstLine(result.stderr)}`);
    const released = await updateSession(ctx, session.id, () => ({
        state: "running",
        waiting_on: null,
        last_activity_at: ctx.now().toISOString(),
    }));
    await appendJournal(ctx, `released \`${session.slug}\` (was waiting on ${session.waiting_on ?? session.state}): ${message}`);
    return released;
}
```

- [ ] **Step 4: Register the command** (import `approveSession` from `./approve`)

```ts
    approve: async (ctx, args) => {
        const [ref, ...words] = args;
        if (!ref) throw usage("missing <session>");
        return json(await approveSession(ctx, ref, words.length ? words.join(" ") : undefined));
    },
```

`USAGE` (indent two spaces, like the other lines): `approve <session> [message…]           release a waiting worker`

- [ ] **Step 5: Run tests and lint** — PASS.
- [ ] **Step 6: Commit** — `Chief: Add approve to release waiting workers`

---

### Task 9: `chief digest` — the pull path

**Files:**

- Create: `src/digest.ts`
- Modify: `src/commands.ts`
- Test: `test/digest.test.ts`

**Interfaces:**

- Consumes: `findSession`, `updateSession`, `transcriptPath`, `digestTranscript`, `readTextIfExists`
- Produces: `digestSession(ctx, ref, recent?): Promise<SessionDigest>` where
  `SessionDigest = { id; slug; state; transcript: string; available: boolean } & Partial<TranscriptDigest>`

- [ ] **Step 1: Write the failing tests**

`test/digest.test.ts`:

```ts
import { afterEach, expect, test } from "bun:test";
import { copyFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { digestSession } from "../src/digest";
import { transcriptPath } from "../src/harness/claude";
import { addSession, loadRegistry } from "../src/registry";
import { sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

function installTranscript(record = sampleRecord()) {
    const path = transcriptPath(env.ctx.claudeHome, record.worktree, record.id);
    mkdirSync(dirname(path), { recursive: true });
    copyFileSync(join(import.meta.dir, "fixtures", "claude-transcript.jsonl"), path);
    return path;
}

test("summarizes the worker's transcript", async () => {
    env = testContext();
    await addSession(env.ctx, sampleRecord());
    const path = installTranscript();
    expect(await digestSession(env.ctx, "chief-cli")).toMatchObject({
        slug: "chief-cli",
        available: true,
        transcript: path,
        lastActivityAt: "2026-09-23T14:40:00.000Z",
        toolCalls: 2,
    });
});

test("advances last_activity_at when the transcript is newer (a missed hook)", async () => {
    env = testContext();
    await addSession(env.ctx, sampleRecord({ last_activity_at: "2026-09-23T14:02:00.000Z" }));
    installTranscript();
    await digestSession(env.ctx, "chief-cli");
    expect((await loadRegistry(env.ctx))[0]?.last_activity_at).toBe("2026-09-23T14:40:00.000Z");
});

test("never moves last_activity_at backwards", async () => {
    env = testContext();
    await addSession(env.ctx, sampleRecord({ last_activity_at: "2026-09-24T00:00:00.000Z" }));
    installTranscript();
    await digestSession(env.ctx, "chief-cli");
    expect((await loadRegistry(env.ctx))[0]?.last_activity_at).toBe("2026-09-24T00:00:00.000Z");
});

test("reports a missing transcript instead of failing", async () => {
    env = testContext();
    await addSession(env.ctx, sampleRecord());
    expect(await digestSession(env.ctx, "chief-cli")).toMatchObject({ available: false });
});
```

- [ ] **Step 2: Run to verify failure** — FAIL.

- [ ] **Step 3: Implement `src/digest.ts`**

```ts
import { ChiefError, type Context } from "./context";
import { readTextIfExists } from "./files";
import { digestTranscript, type TranscriptDigest, transcriptPath } from "./harness/claude";
import { findSession, type SessionState, updateSession } from "./registry";

export type SessionDigest = {
    id: string;
    slug: string;
    state: SessionState;
    transcript: string;
    available: boolean;
} & Partial<TranscriptDigest>;

export async function digestSession(ctx: Context, ref: string, recent = 3): Promise<SessionDigest> {
    const session = await findSession(ctx, ref);
    if (session.harness !== "claude") throw new ChiefError(`digest is not supported for ${session.harness} yet`);
    const transcript = transcriptPath(ctx.claudeHome, session.worktree, session.id);
    const header = { id: session.id, slug: session.slug, state: session.state, transcript };
    const text = await readTextIfExists(transcript);
    if (text === null) return { ...header, available: false };

    const digest = digestTranscript(text, recent);
    const seen = digest.lastActivityAt;
    if (seen) await updateSession(ctx, session.id, (s) => (seen > s.last_activity_at ? { last_activity_at: seen } : {}));
    return { ...header, available: true, ...digest };
}
```

(ISO-8601 UTC strings compare correctly as strings.)

- [ ] **Step 4: Register the command** (import `digestSession` from `./digest`)

```ts
    digest: async (ctx, args) => {
        const { values, positionals } = parse(args, { recent: { type: "string", default: "3" } });
        return json(await digestSession(ctx, requirePositional(positionals, 0, "session"), Number(values.recent)));
    },
```

`USAGE` (indent two spaces, like the other lines): `digest <session> [--recent N]          summarize the worker's transcript`

- [ ] **Step 5: Run tests and lint** — PASS.
- [ ] **Step 6: Commit** — `Chief: Add digest for worker status (pull path)`

---

### Task 10: `chief briefing`

**Files:**

- Create: `src/quota.ts`, `src/briefing.ts`
- Modify: `src/commands.ts`
- Test: `test/quota.test.ts`, `test/briefing.test.ts`

**Interfaces:**

- Consumes: `loadRegistry`, `isActive`, `tailJournal`, `transcriptPath`, `minutesBetween`
- Produces:
    - `interface Quota { five_hour_percent: number | null; five_hour_resets_at: string | null; seven_day_percent: number | null; seven_day_resets_at: string | null; updated_at: string | null }`
    - `readQuota(ctx): Promise<Quota | null>`
    - `interface BriefingSession` — record fields the agent needs plus `idle_minutes`, `stalled`
    - `buildBriefing(ctx): Promise<Briefing>` with `{ generated_at, sessions, journal_tail, quota, context_files }` (Task 12 adds `updates`)
    - `STALL_HOURS = 24`, `JOURNAL_TAIL = 15`

- [ ] **Step 1: Write the failing tests**

`test/quota.test.ts`:

```ts
import { afterEach, expect, test } from "bun:test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { readQuota } from "../src/quota";
import { testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const writeQuota = (text: string) => {
    mkdirSync(env.ctx.claudeHome, { recursive: true });
    writeFileSync(join(env.ctx.claudeHome, "abtop-rate-limits.json"), text);
};

test("reads usage percentages and converts reset epochs to ISO", async () => {
    env = testContext();
    writeQuota(JSON.stringify({
        five_hour: { used_percentage: 24, resets_at: 1789791600 },
        seven_day: { used_percentage: 61, resets_at: 1790000000 },
        updated_at: "2026-09-23T13:00:00Z",
    }));
    expect(await readQuota(env.ctx)).toEqual({
        five_hour_percent: 24,
        five_hour_resets_at: new Date(1789791600 * 1000).toISOString(),
        seven_day_percent: 61,
        seven_day_resets_at: new Date(1790000000 * 1000).toISOString(),
        updated_at: "2026-09-23T13:00:00Z",
    });
});

test("is null when the file is missing or unreadable", async () => {
    env = testContext();
    expect(await readQuota(env.ctx)).toBeNull();
    writeQuota("{bad");
    expect(await readQuota(env.ctx)).toBeNull();
});
```

`test/briefing.test.ts`:

```ts
import { afterEach, expect, test } from "bun:test";
import { mkdirSync, utimesSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { buildBriefing } from "../src/briefing";
import { transcriptPath } from "../src/harness/claude";
import { appendJournal } from "../src/journal";
import { addSession } from "../src/registry";
import { sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const NOW = "2026-09-26T14:00:00Z";

test("lists active sessions, waiting first, with idle time and stall flags", async () => {
    env = testContext({ now: NOW });
    await addSession(env.ctx, sampleRecord({ id: "r1", slug: "fresh", last_activity_at: "2026-09-26T13:40:00.000Z" }));
    await addSession(env.ctx, sampleRecord({ id: "r2", slug: "stale", last_activity_at: "2026-09-23T14:00:00.000Z" }));
    await addSession(env.ctx, sampleRecord({ id: "w1", slug: "needs-you", state: "waiting", waiting_on: "approve-tests" }));
    await addSession(env.ctx, sampleRecord({ id: "d1", slug: "finished", state: "done" }));
    const { sessions } = await buildBriefing(env.ctx);
    expect(sessions.map((s) => [s.slug, s.idle_minutes, s.stalled])).toEqual([
        ["needs-you", 4318, false],
        ["stale", 4320, true],
        ["fresh", 20, false],
    ]);
});

test("uses the transcript's modification time when it is newer than the record", async () => {
    env = testContext({ now: NOW });
    const record = sampleRecord({ last_activity_at: "2026-09-23T14:00:00.000Z" });
    await addSession(env.ctx, record);
    const path = transcriptPath(env.ctx.claudeHome, record.worktree, record.id);
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, "");
    const tenMinutesAgo = new Date(Date.parse(NOW) - 10 * 60_000);
    utimesSync(path, tenMinutesAgo, tenMinutesAgo);
    const [session] = (await buildBriefing(env.ctx)).sessions;
    expect(session).toMatchObject({ idle_minutes: 10, stalled: false });
});

test("includes the journal tail, quota, and context file paths", async () => {
    env = testContext({ now: NOW });
    await appendJournal(env.ctx, "something happened");
    const briefing = await buildBriefing(env.ctx);
    expect(briefing.generated_at).toBe("2026-09-26T14:00:00.000Z");
    expect(briefing.journal_tail).toEqual(["## 2026-09-26", "- 14:00 something happened"]);
    expect(briefing.quota).toBeNull();
    expect(briefing.context_files).toEqual({
        projects: "~/Personal/Projects/Current.md",
        human: "~/.config/ai/HUMAN.md",
    });
});
```

- [ ] **Step 2: Run to verify failure** — FAIL.

- [ ] **Step 3: Implement**

`src/quota.ts`:

```ts
import { join } from "node:path";
import type { Context } from "./context";
import { readTextIfExists } from "./files";

// Written by abtop's statusline hook (see claude/statusline); read to decide when to route work elsewhere.
const QUOTA_FILE = "abtop-rate-limits.json";

export interface Quota {
    five_hour_percent: number | null;
    five_hour_resets_at: string | null;
    seven_day_percent: number | null;
    seven_day_resets_at: string | null;
    updated_at: string | null;
}

interface Window {
    used_percentage?: number;
    resets_at?: number;
}

export async function readQuota(ctx: Context): Promise<Quota | null> {
    const text = await readTextIfExists(join(ctx.claudeHome, QUOTA_FILE));
    if (text === null) return null;
    try {
        const raw = JSON.parse(text) as { five_hour?: Window; seven_day?: Window; updated_at?: string };
        return {
            five_hour_percent: raw.five_hour?.used_percentage ?? null,
            five_hour_resets_at: epochToIso(raw.five_hour?.resets_at),
            seven_day_percent: raw.seven_day?.used_percentage ?? null,
            seven_day_resets_at: epochToIso(raw.seven_day?.resets_at),
            updated_at: raw.updated_at ?? null,
        };
    } catch {
        return null; // advisory data: a bad file must not break the briefing
    }
}

function epochToIso(seconds: number | undefined): string | null {
    return typeof seconds === "number" ? new Date(seconds * 1000).toISOString() : null;
}
```

`src/briefing.ts`:

```ts
import { stat } from "node:fs/promises";
import type { Context } from "./context";
import { isNotFound } from "./files";
import { transcriptPath } from "./harness/claude";
import { tailJournal } from "./journal";
import { readQuota, type Quota } from "./quota";
import { isActive, loadRegistry, type SessionRecord, type SessionState } from "./registry";
import { minutesBetween } from "./time";

export const STALL_HOURS = 24;
export const JOURNAL_TAIL = 15;
const STATE_ORDER: SessionState[] = ["waiting", "blocked", "running"];
const CONTEXT_FILES = { projects: "~/Personal/Projects/Current.md", human: "~/.config/ai/HUMAN.md" };

export type BriefingSession = Pick<
    SessionRecord,
    "id" | "slug" | "goal" | "harness" | "model" | "state" | "waiting_on" | "summary" | "autonomy" | "worktree" | "attach"
> & { idle_minutes: number; stalled: boolean };

export interface Briefing {
    generated_at: string;
    sessions: BriefingSession[];
    journal_tail: string[];
    quota: Quota | null;
    context_files: typeof CONTEXT_FILES;
}

export async function buildBriefing(ctx: Context): Promise<Briefing> {
    const active = (await loadRegistry(ctx)).filter(isActive);
    const sessions = await Promise.all(active.map((s) => briefSession(ctx, s)));
    return {
        generated_at: ctx.now().toISOString(),
        sessions: sessions.sort(byUrgency),
        journal_tail: await tailJournal(ctx, JOURNAL_TAIL),
        quota: await readQuota(ctx),
        context_files: CONTEXT_FILES,
    };
}

async function briefSession(ctx: Context, s: SessionRecord): Promise<BriefingSession> {
    const lastActivity = latest(s.last_activity_at, await transcriptModifiedAt(ctx, s));
    const idle = minutesBetween(lastActivity, ctx.now());
    const { id, slug, goal, harness, model, state, waiting_on, summary, autonomy, worktree, attach } = s;
    return {
        id, slug, goal, harness, model, state, waiting_on, summary, autonomy, worktree, attach,
        idle_minutes: idle,
        stalled: state === "running" && idle >= STALL_HOURS * 60,
    };
}

// The file's mtime is a cheap liveness signal that works even when a Stop hook never fired.
async function transcriptModifiedAt(ctx: Context, s: SessionRecord): Promise<string | null> {
    if (s.harness !== "claude") return null;
    try {
        return (await stat(transcriptPath(ctx.claudeHome, s.worktree, s.id))).mtime.toISOString();
    } catch (error) {
        if (isNotFound(error)) return null;
        throw error;
    }
}

function latest(a: string, b: string | null): string {
    return b && b > a ? b : a;
}

// Most urgent first; within a state, the longest idle first.
function byUrgency(a: BriefingSession, b: BriefingSession): number {
    return STATE_ORDER.indexOf(a.state) - STATE_ORDER.indexOf(b.state) || b.idle_minutes - a.idle_minutes;
}
```

- [ ] **Step 4: Register the command** (import `buildBriefing` from `./briefing`)

```ts
    briefing: async (ctx) => json(await buildBriefing(ctx)),
```

`USAGE` (indent two spaces, like the other lines): `briefing                               everything a session start needs, as JSON`

- [ ] **Step 5: Run tests and lint** — PASS.
- [ ] **Step 6: Commit** — `Chief: Add briefing for session start`

---

### Task 11: The Chief agent

Not unit-testable; verified by running it. Answer the Open Questions first.

**Files:**

- Create: `ai/agents/chief-of-staff/AGENT.md`
- Create: `opencode/agents/chief-of-staff.md` (symlink)
- Modify: `sh/ai.sh` (add the `cos` alias; shared by Bash and Zsh)
- Modify: `ai/tools/chief-of-staff/README.md` (how to start Chief)

- [ ] **Step 1: Write `ai/agents/chief-of-staff/AGENT.md`**

````markdown
---
name: chief-of-staff
description: Chief of Staff — the session entry point. Shows work in flight, suggests what to do next, spawns and tracks worker sessions across harnesses. A manager, not a worker. Start with `claude --agent chief-of-staff` (alias `cos`).
model: inherit
---

# Chief of Staff

You are the human's Chief of Staff. You manage work; you do not do it. Anything
that needs code written, files edited, or research done goes to a worker session
you spawn with `chief spawn`. Your own tools are the `chief` CLI, reading files,
and talking with the human.

The design behind this role: `~/.config/ai/docs/plans/2026-09-23-chief-of-staff-design.md`.

## Opening a session

1. Run `chief briefing` (JSON). Do not run other commands first.
2. Read the two `context_files` (current projects, the human's goals) only if you
   need them to justify a suggestion.
3. Render three zones, fitting one screen:

   ```text
   N sessions in flight

     ⏸  <slug>   waiting on you — <summary>          (<idle>)
     ▶  <slug>   running — <summary>                 (<idle>)
     ⚠  <slug>   stalled <idle> — <summary>

   Since you were last here
     • <update or journal highlight>

   Suggestions
     1. <suggestion, tied to something above>
   ```

   Use ⏸ for `waiting`, ✖ for `blocked`, ⚠ when `stalled`, ▶ otherwise. Idle
   times as `20m`, `2h`, `3d`.
4. Every suggestion must point at something in the first two zones. Generic
   advice ("consider writing tests") is not a suggestion. Zero suggestions is fine.
5. You may offer to run `/morning` for email, calendar, and news. Do not absorb it.

For a session whose summary is stale or missing, run `chief digest <slug>` before
describing it.

## Spawning work

`chief spawn --goal "<one sentence>" --repo <dir> [--slug s] [--model m] [--effort e] [--autonomy auto|checkpointed]`

Before spawning, tell the human in one line: the slug, model and effort, and the
autonomy you chose and why.

**Model and effort** (Claude only for now; Codex and OpenCode arrive later):

| Work | Choice |
| --- | --- |
| Difficult: architecture, long-horizon, nasty debugging | `--model fable --effort xhigh` |
| Default coding | `--model opus --effort high` (the defaults) |
| Mechanical or bulk | `--model sonnet --effort medium` |

- Start one tier down for mechanical work; escalate on failure.
- Never silently downgrade work already declared Opus-worthy. If you change your
  mind mid-task, say so.
- Check `quota` in the briefing. Above 80% of the five-hour window, tell the human
  before spawning more Opus/Fable work, and mention when it resets.

**Autonomy:** default `auto`. Choose `checkpointed` when the goal is ambiguous, the
blast radius is large, or the human is new to this kind of task. State which and why.

## Approval tiers

| You handle silently | You escalate, always | Your judgment |
| --- | --- | --- |
| Tool permissions, lint fixes, green-keeping refactors, commit messages, review-round fixes | Test and spec design for non-trivial work, push and PR, destructive operations, mid-task scope changes | Everything else |

- When you decide **not** to escalate a judgment-tier item, record why:
  `chief note "<slug>: did not escalate <what> because <why>"`. This log is how the
  tiers get tuned.
- The escalation inbox is the set of `waiting` sessions. To release one after the
  human decides: `chief approve <slug> <the human's decision, in their words>`.
  Never approve an always-escalate item on your own.
- `waiting_on: unreported-stop` means the worker stopped without saying why. Run
  `chief digest <slug>` and tell the human what it seems to need.

## Closing work

When the human confirms a finished session is merged or dropped:
`chief close <slug> [--summary "<outcome>"]` or `chief close <slug> --abandon`.

## Tone

Brief. Lead with what needs the human. No preamble, no recap of what they already
saw. Give a recommendation, not a menu.
````

- [ ] **Step 2: Verify Claude loads it**

Run: `claude --agent chief-of-staff -p "In one line: what is your role, and what is the first command you run?"`
Expected: mentions Chief of Staff and `chief briefing`.

- [ ] **Step 3: Mirror to OpenCode (cross-surface parity)**

```bash
mkdir -p ~/.config/opencode/agents
ln -s ../../ai/agents/chief-of-staff/AGENT.md ~/.config/opencode/agents/chief-of-staff.md
opencode agent list
```

Expected: `chief-of-staff` listed. If OpenCode rejects the frontmatter, remove the
symlink and instead add an `agent.chief-of-staff` entry to `opencode/opencode.jsonc`
with `"mode": "primary"` and `"prompt": "{file:../ai/agents/chief-of-staff/AGENT.md}"`;
tell the human which route was taken. Codex has no agent files; it reads
`codex/AGENTS.md`, so nothing to mirror there yet.

- [ ] **Step 4: Add the launcher alias** to `sh/ai.sh`:

```bash
# Chief of Staff: the manager session that tracks and spawns worker sessions.
alias cos='claude --agent chief-of-staff'
```

- [ ] **Step 5: End-to-end dry run.** Start `cos`. With at least one real session in
  the registry (spawn one via Chief), confirm: the briefing renders in three zones;
  suggestions cite something concrete; a spawn states model and autonomy; `approve`
  releases a waiting worker. Note anything the agent got wrong and fix the wording.
- [ ] **Step 6: Commit** — `Chief: Add the Chief of Staff agent` (AGENT.md, OpenCode link, alias, README).

---

### Task 12: Scheduled-task updates — `config.toml` and `chief updates`

**Files:**

- Create: `src/config.ts`, `src/updates.ts`
- Modify: `src/commands.ts` (`init` writes the config template; add `updates`), `src/briefing.ts` (add `updates`)
- Test: `test/config.test.ts`, `test/updates.test.ts`; extend `test/briefing.test.ts`, `test/commands.test.ts`

**Interfaces:**

- Consumes: `readTextIfExists`, `writeAtomically`, `expandHome`
- Produces:
    - `interface ChiefConfig { watch: { dirs: string[] } }` (dirs already `~`-expanded)
    - `CONFIG_TEMPLATE: string`, `loadConfig(ctx): Promise<ChiefConfig>`
    - `interface Update { task: string; date: string; path: string; highlights: string[] }`
    - `unreviewedUpdates(ctx): Promise<Update[]>` — newest first
    - `markReviewed(ctx, task?): Promise<number>` — how many updates were marked
    - `highlights(markdown, limit?): string[]`
    - `Briefing.updates: Update[]`

- [ ] **Step 1: Write the failing tests**

`test/config.test.ts`:

```ts
import { afterEach, expect, test } from "bun:test";
import { writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { CONFIG_TEMPLATE, loadConfig } from "../src/config";
import { testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const writeConfig = (text: string) => writeFileSync(join(env.ctx.home, "config.toml"), text);

test("defaults to watching nothing when there is no config", async () => {
    env = testContext();
    expect(await loadConfig(env.ctx)).toEqual({ watch: { dirs: [] } });
});

test("expands ~ in watch dirs", async () => {
    env = testContext();
    writeConfig('[watch]\ndirs = ["~/a", "/b"]\n');
    expect((await loadConfig(env.ctx)).watch.dirs).toEqual([join(homedir(), "a"), "/b"]);
});

test("the template parses and watches mac-software-updates", async () => {
    env = testContext();
    writeConfig(CONFIG_TEMPLATE);
    expect((await loadConfig(env.ctx)).watch.dirs).toEqual([join(homedir(), ".local/share/ai/mac-software-updates")]);
});

test("reports bad TOML and bad shapes, naming the file", async () => {
    env = testContext();
    writeConfig("[watch\n");
    await expect(loadConfig(env.ctx)).rejects.toThrow(/config\.toml/);
    writeConfig('[watch]\ndirs = "not-a-list"\n');
    await expect(loadConfig(env.ctx)).rejects.toThrow(/list of strings/);
});
```

`test/updates.test.ts`:

```ts
import { afterEach, expect, test } from "bun:test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { highlights, markReviewed, unreviewedUpdates } from "../src/updates";
import { testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

function setup() {
    env = testContext();
    const brew = join(env.root, "mac-software-updates");
    const retro = join(env.root, "workflow-retro");
    for (const dir of [brew, retro]) mkdirSync(dir, { recursive: true });
    writeFileSync(join(brew, "2026-09-21.md"), "# Updates\n\n- 6 upgrades, nothing notable\n");
    writeFileSync(join(brew, "2026-09-22.md"), "# Updates\n\n- 14 upgrades\n- jj 0.32→0.33 (breaking)\n");
    writeFileSync(join(brew, "notes.txt"), "ignored: not a dated file");
    writeFileSync(join(retro, "2026-09-21.md"), "3 friction items\n");
    writeFileSync(join(env.ctx.home, "config.toml"), `[watch]\ndirs = ["${brew}", "${retro}", "${join(env.root, "missing")}"]\n`);
    return { brew, retro };
}

test("lists dated reports from every watched dir, newest first, skipping missing dirs", async () => {
    const { brew } = setup();
    const updates = await unreviewedUpdates(env.ctx);
    expect(updates.map((u) => [u.task, u.date])).toEqual([
        ["mac-software-updates", "2026-09-22"],
        ["mac-software-updates", "2026-09-21"],
        ["workflow-retro", "2026-09-21"],
    ]);
    expect(updates[0]).toMatchObject({ path: join(brew, "2026-09-22.md"), highlights: ["14 upgrades", "jj 0.32→0.33 (breaking)"] });
});

test("marking reviewed hides everything up to now, and new reports reappear", async () => {
    const { brew } = setup();
    expect(await markReviewed(env.ctx)).toBe(3);
    expect(await unreviewedUpdates(env.ctx)).toEqual([]);
    writeFileSync(join(brew, "2026-09-23.md"), "- 2 upgrades\n");
    expect((await unreviewedUpdates(env.ctx)).map((u) => u.date)).toEqual(["2026-09-23"]);
});

test("marking one task reviewed leaves the others", async () => {
    setup();
    await markReviewed(env.ctx, "mac-software-updates");
    expect((await unreviewedUpdates(env.ctx)).map((u) => u.task)).toEqual(["workflow-retro"]);
});

test("highlights skip headings, frontmatter fences, and bullet markers", () => {
    expect(highlights("---\n# Title\n\n* one\n- two\nthree\nfour\n")).toEqual(["one", "two", "three"]);
});
```

Extend `test/briefing.test.ts`:

```ts
test("includes unreviewed scheduled-task updates", async () => {
    env = testContext({ now: NOW });
    const dir = join(env.root, "mac-software-updates");
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "2026-09-26.md"), "- 3 upgrades\n");
    writeFileSync(join(env.ctx.home, "config.toml"), `[watch]\ndirs = ["${dir}"]\n`);
    expect((await buildBriefing(env.ctx)).updates.map((u) => u.date)).toEqual(["2026-09-26"]);
});
```

(add `join` to the `node:path` import there.)

Extend `test/commands.test.ts`'s `init` describe:

```ts
    test("writes the config template once, never overwriting edits", async () => {
        env = testContext();
        await run("init");
        writeFileSync(join(env.ctx.home, "config.toml"), "# mine\n");
        await run("init");
        expect(readFileSync(join(env.ctx.home, "config.toml"), "utf8")).toBe("# mine\n");
    });
```

(add `writeFileSync` to the `node:fs` import there.) And one for the command:

```ts
test("updates lists, and --mark-reviewed clears", async () => {
    env = testContext();
    const dir = join(env.root, "t");
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "2026-09-22.md"), "- x\n");
    writeFileSync(join(env.ctx.home, "config.toml"), `[watch]\ndirs = ["${dir}"]\n`);
    expect(JSON.parse((await run("updates")).output)).toHaveLength(1);
    await run("updates", "--mark-reviewed");
    expect(JSON.parse((await run("updates")).output)).toEqual([]);
});
```

- [ ] **Step 2: Run to verify failure** — FAIL.

- [ ] **Step 3: Implement**

`src/config.ts`:

```ts
import { join, resolve } from "node:path";
import { ChiefError, type Context } from "./context";
import { readTextIfExists } from "./files";
import { expandHome } from "./text";

export interface ChiefConfig {
    watch: { dirs: string[] };
}

export const CONFIG_TEMPLATE = `# Chief of Staff configuration. The only hand-edited file in this directory.

[watch]
# Directories where scheduled tasks write dated Markdown reports (YYYY-MM-DD.md).
dirs = [
  "~/.local/share/ai/mac-software-updates",
]
`;

export function configPath(ctx: Context): string {
    return join(ctx.home, "config.toml");
}

export async function loadConfig(ctx: Context): Promise<ChiefConfig> {
    const path = configPath(ctx);
    const text = await readTextIfExists(path);
    if (text === null) return { watch: { dirs: [] } };
    let parsed: { watch?: { dirs?: unknown } };
    try {
        parsed = Bun.TOML.parse(text) as typeof parsed;
    } catch (error) {
        throw new ChiefError(`${path}: ${(error as Error).message}`);
    }
    const dirs = parsed.watch?.dirs ?? [];
    if (!Array.isArray(dirs) || !dirs.every((d) => typeof d === "string")) {
        throw new ChiefError(`${path}: [watch] dirs must be a list of strings`);
    }
    return { watch: { dirs: dirs.map((dir) => resolve(expandHome(dir))) } };
}
```

`src/updates.ts`:

```ts
import { readdir, readFile } from "node:fs/promises";
import { basename, dirname, join } from "node:path";
import { loadConfig } from "./config";
import type { Context } from "./context";
import { isNotFound, readTextIfExists, writeAtomically } from "./files";

const DATED_REPORT = /^(\d{4}-\d{2}-\d{2})\.md$/;
const HIGHLIGHTS = 3;

export interface Update {
    task: string; // the watched directory's name
    date: string;
    path: string;
    highlights: string[];
}

type Watermarks = Record<string, string>; // watched dir → latest reviewed date

export async function unreviewedUpdates(ctx: Context): Promise<Update[]> {
    const [{ watch }, marks] = await Promise.all([loadConfig(ctx), loadWatermarks(ctx)]);
    const perDir = await Promise.all(watch.dirs.map((dir) => reportsAfter(dir, marks[dir] ?? "")));
    return perDir.flat().sort((a, b) => b.date.localeCompare(a.date) || a.task.localeCompare(b.task));
}

export async function markReviewed(ctx: Context, task?: string): Promise<number> {
    const marking = (await unreviewedUpdates(ctx)).filter((u) => !task || u.task === task);
    const marks = marking.reduce<Watermarks>((acc, u) => {
        const dir = dirname(u.path);
        return u.date > (acc[dir] ?? "") ? { ...acc, [dir]: u.date } : acc;
    }, await loadWatermarks(ctx));
    await writeAtomically(watermarkPath(ctx), `${JSON.stringify(marks, null, 2)}\n`);
    return marking.length;
}

export function highlights(markdown: string, limit = HIGHLIGHTS): string[] {
    return markdown
        .split("\n")
        .map((line) => line.trim())
        .filter((line) => line && !line.startsWith("#") && line !== "---")
        .map((line) => line.replace(/^[-*]\s+/, ""))
        .slice(0, limit);
}

async function reportsAfter(dir: string, after: string): Promise<Update[]> {
    const dates = (await listDir(dir))
        .map((name) => DATED_REPORT.exec(name)?.[1])
        .filter((date): date is string => date !== undefined && date > after);
    return Promise.all(
        dates.map(async (date) => {
            const path = join(dir, `${date}.md`);
            return { task: basename(dir), date, path, highlights: highlights(await readFile(path, "utf8")) };
        }),
    );
}

async function listDir(dir: string): Promise<string[]> {
    try {
        return await readdir(dir);
    } catch (error) {
        if (isNotFound(error)) return []; // a task that has not run yet
        throw error;
    }
}

async function loadWatermarks(ctx: Context): Promise<Watermarks> {
    const text = await readTextIfExists(watermarkPath(ctx));
    return text ? JSON.parse(text) : {};
}

function watermarkPath(ctx: Context): string {
    return join(ctx.home, "reviewed.json");
}
```

Watermarks are keyed by `dirname(report path)`, which must equal the configured
dir. `loadConfig` normalizes dirs with `resolve`, so a trailing slash in
`config.toml` cannot cause a mismatch.

In `src/commands.ts` (imports: `writeFile` from `node:fs/promises`; `readTextIfExists` from `./files`;
`CONFIG_TEMPLATE`, `configPath` from `./config`; `markReviewed`, `unreviewedUpdates` from `./updates`),
change `initHome` to also write the template when absent:

```ts
export async function initHome(ctx: Context): Promise<void> {
    await Promise.all(["journal", "hooks"].map((dir) => mkdir(join(ctx.home, dir), { recursive: true })));
    if ((await readTextIfExists(configPath(ctx))) === null) await writeFile(configPath(ctx), CONFIG_TEMPLATE);
}
```

Add to `COMMANDS`:

```ts
    updates: async (ctx, args) => {
        const { values } = parse(args, { "mark-reviewed": { type: "boolean" }, task: { type: "string" } });
        if (values["mark-reviewed"]) return { output: `Marked ${await markReviewed(ctx, values.task)} reviewed.` };
        return json(await unreviewedUpdates(ctx));
    },
```

`USAGE` (indent two spaces, like the other lines): `updates [--mark-reviewed [--task name]]  unreviewed scheduled-task reports`

In `src/briefing.ts`, add `updates: Update[]` to `Briefing` and
`updates: await unreviewedUpdates(ctx),` to the object `buildBriefing` returns.

Add one line to AGENT.md's "Opening a session" step 3: *"Since you were last here"
lists `briefing.updates` (one line each: task, date, the most notable highlight),
then journal highlights. After the human has seen them, run
`chief updates --mark-reviewed`.*

- [ ] **Step 4: Run tests and lint** — PASS. Then refactor `markReviewed` as noted; re-run.
- [ ] **Step 5: Commit** — `Chief: Surface unreviewed scheduled-task reports`

---

### Task 13: `mac-software-updates` writes its report to disk

**Files:**

- Modify: `~/.config/claude/scheduled-tasks/mac-software-updates/SKILL.md` (**untracked** in git; the change is local only, so tell the human)

- [ ] **Step 1: Append to the SKILL.md**

```markdown

When the update is finished, also save the summary (everything under the title
heading) as Markdown to `~/.local/share/ai/mac-software-updates/YYYY-MM-DD.md`,
using the same date, creating the directory if needed. Chief of Staff reads it.
```

- [ ] **Step 2: Initialize Chief's state** — `chief init`, then confirm `~/.local/share/ai/chief-of-staff/config.toml` watches `~/.local/share/ai/mac-software-updates`.

- [ ] **Step 3: Verify.** After the next scheduled run (or a manual run of the task),
  `chief updates` lists today's report with sensible highlights. Output from before
  this change is not backfilled; that is intended (spec, "Scheduled Task Reports").

- [ ] **Step 4: Flag the stale `lastRunAt`** (spec: the task reports today's
  `lastRunAt` but its newest recorded run is 2026-08-27). Offer the human a separate
  task to investigate; do not fix it here.

- [ ] **Step 5: No commit** (file is untracked). If the human wants
  `claude/scheduled-tasks/` tracked, that is a separate decision: check it for
  personal data first.

---

## Finishing

After Task 13:

1. Full `make specs && make lint`.
2. The 3-review process over the whole branch (`/review`); fix findings.
3. Update `ai/tools/chief-of-staff/README.md` so it lists every command.
4. Tell the human that design build-order steps 0–5 are done. Do not edit the
   design doc; it is a read-only source document, and its Status line is theirs to update.
5. Write the follow-on plan for steps 6–7 from `docs/spike-notes.md` and what was
   learned using Chief day to day.
