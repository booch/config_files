import { mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
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
    // Canned results for non-git commands, keyed by "argv0 argv1" (e.g. "claude --bg") or argv0.
    fakes?: Record<string, Partial<RunResult>>;
}

// What an idle machine answers when no fake overrides it.
const DEFAULT_FAKES: Record<string, Partial<RunResult>> = { "claude agents": { stdout: "[]" } };

// Real git (fast, filesystem-only); everything else is recorded and faked.
export function testContext(options: TestContextOptions = {}) {
    const root = realpathSync(mkdtempSync(join(tmpdir(), "chief-test-")));
    const calls: RecordedCall[] = [];
    const fakes = { ...DEFAULT_FAKES, ...options.fakes };
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
            return {
                exitCode: 0,
                stdout: "",
                stderr: "",
                ...(fakes[argv.slice(0, 2).join(" ")] ?? fakes[argv[0] ?? ""]),
            };
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
        [
            "-c",
            "user.name=Test",
            "-c",
            "user.email=test@example.com",
            "commit",
            "-q",
            "--allow-empty",
            "-m",
            "init",
        ],
    ]) {
        const result = await realRunner(["git", "-C", dir, ...args]);
        if (result.exitCode !== 0) throw new Error(result.stderr);
    }
    return dir;
}

export function readJournal(ctx: Context, month = "2026-09"): string {
    return readFileSync(join(ctx.home, "journal", `${month}.md`), "utf8");
}

// Creates a watched dir per task under the test root, each holding its dated reports
// ({ task: { "YYYY-MM-DD": markdown } }), and lists them all in config.toml. A task with no
// reports gets no dir, like a scheduled task that has not run yet. Returns task → dir.
export function watchReports(
    env: { ctx: Context; root: string },
    reports: Record<string, Record<string, string>>,
): Record<string, string> {
    const dirs: Record<string, string> = {};
    for (const [task, byDate] of Object.entries(reports)) {
        const dir = join(env.root, task);
        dirs[task] = dir;
        for (const [date, markdown] of Object.entries(byDate)) {
            mkdirSync(dir, { recursive: true });
            writeFileSync(join(dir, `${date}.md`), markdown);
        }
    }
    const config = `[watch]\ndirs = ${JSON.stringify(Object.values(dirs))}\n`;
    writeFileSync(join(env.ctx.home, "config.toml"), config);
    return dirs;
}

export const CLOSED_AT = "2026-09-24T09:00:00.000Z";

export function sampleRecord(overrides: Partial<SessionRecord> = {}): SessionRecord {
    return {
        id: "01a0d1ea-6d1d-7000-834f-27da05c179e5",
        slug: "chief-cli",
        goal: "Implement chief spawn + registry",
        harness: "claude",
        harness_ref: "5f3a9c00",
        harness_session_id: "5f3a9c00-1111-4222-8333-444455556666",
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
        closed_at: null,
        attach: {
            terminal: "claude attach 5f3a9c00",
            resume: "cd '/worktrees/repo/chief-cli' && claude --resume 5f3a9c00-1111-4222-8333-444455556666",
        },
        ...overrides,
    };
}
