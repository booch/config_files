import { afterEach, describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { runCommand } from "../src/commands";
import { KICKOFF_FILE } from "../src/kickoff";
import { addSession, loadRegistry } from "../src/registry";
import { type SpawnOptions, spawnSession } from "../src/spawn";
import { CLOSED_AT, makeGitRepo, sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const BG_OUTPUT = readFileSync(join(import.meta.dir, "fixtures", "claude-bg-output.txt"), "utf8");
const AGENTS_JSON = JSON.stringify([
    { id: "ca42e85d", sessionId: "ca42e85d-bc19-44c5-8a7a-244064a4c0e5" },
]);
const CLAUDE_FAKES = {
    "claude --bg": { stdout: BG_OUTPUT },
    "claude agents": { stdout: AGENTS_JSON },
};
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
        env = testContext({ fakes: CLAUDE_FAKES });
        const { repo, record } = await spawnDefault();
        expect(record.id).toMatch(UUID_V7);
        expect(record).toMatchObject({
            slug: "fix-the-login-bug",
            branch: "fix-the-login-bug",
            repo,
            worktree: join(env.ctx.worktreeRoot, "repo", "fix-the-login-bug"),
            state: "running",
            spawned_at: "2026-09-23T14:02:00.000Z",
            harness_ref: "ca42e85d",
            harness_session_id: "ca42e85d-bc19-44c5-8a7a-244064a4c0e5",
        });
        expect(await loadRegistry(env.ctx)).toEqual([record]);
    });

    test("writes the kickoff prompt into the worktree", async () => {
        env = testContext({ fakes: CLAUDE_FAKES });
        const { record } = await spawnDefault();
        const prompt = readFileSync(join(record.worktree, KICKOFF_FILE), "utf8");
        expect(prompt).toContain("Fix the login bug");
        expect(prompt).toContain(`bun '/opt/chief/src/cli.ts' report ${record.id}`);
    });

    test("launches claude in the worktree with a Stop hook that reports back", async () => {
        env = testContext({ fakes: CLAUDE_FAKES });
        const { record } = await spawnDefault();
        const [call] = env.calls;
        expect(call?.cwd).toBe(record.worktree);
        expect(call?.argv.slice(0, 2)).toEqual(["claude", "--bg"]);
        expect(call?.argv).not.toContain("--session-id");
        expect(env.calls[1]?.argv).toEqual(["claude", "agents", "--json"]);
        const settingsPath = call?.argv[call.argv.indexOf("--settings") + 1] ?? "";
        const settings = JSON.parse(readFileSync(settingsPath, "utf8"));
        expect(settings.hooks.Stop[0].hooks[0].command).toBe(
            `bun '/opt/chief/src/cli.ts' report ${record.id} --stopped`,
        );
    });

    test("journals the spawn", async () => {
        env = testContext({ fakes: CLAUDE_FAKES });
        await spawnDefault();
        expect(readFileSync(join(env.ctx.home, "journal", "2026-09.md"), "utf8")).toContain(
            "spawned `fix-the-login-bug` (claude/opus/high, auto) — goal: Fix the login bug",
        );
    });

    test("records a failed launch as blocked instead of losing it", async () => {
        env = testContext({
            fakes: { "claude --bg": { exitCode: 1, stderr: "error: not logged in\nmore" } },
        });
        const { record } = await spawnDefault();
        expect(record.state).toBe("blocked");
        expect(record.summary).toBe("launch failed: error: not logged in");
        expect(record.harness_session_id).toBeNull();
        expect(env.calls).toHaveLength(1);
    });

    test("uses an explicit --slug after validating it", async () => {
        env = testContext({ fakes: CLAUDE_FAKES });
        expect((await spawnDefault({ slug: "login" })).record.slug).toBe("login");
        await expect(spawnDefault({ slug: "../evil" })).rejects.toThrow(/invalid slug/);
    });

    test("refuses a slug already used by an active session", async () => {
        env = testContext({ fakes: CLAUDE_FAKES });
        await addSession(env.ctx, sampleRecord({ slug: "login" }));
        await expect(spawnDefault({ slug: "login" })).rejects.toThrow(/already in use/);
    });

    test("refuses a slug whose worker is done but not yet closed", async () => {
        env = testContext({ fakes: CLAUDE_FAKES });
        await addSession(env.ctx, sampleRecord({ slug: "login", state: "done" }));
        await expect(spawnDefault({ slug: "login" })).rejects.toThrow(/already in use/);
    });

    test("reuses the slug of a closed session", async () => {
        env = testContext({ fakes: CLAUDE_FAKES });
        await addSession(
            env.ctx,
            sampleRecord({ slug: "login", state: "abandoned", closed_at: CLOSED_AT }),
        );
        expect((await spawnDefault({ slug: "login" })).record).toMatchObject({
            slug: "login",
            closed_at: null,
        });
    });

    test("refuses harnesses not supported yet", async () => {
        env = testContext();
        await expect(spawnDefault({ harness: "codex" })).rejects.toThrow(/not supported yet/);
    });
});

test("the spawn command applies defaults: claude, opus, high, auto", async () => {
    env = testContext({ fakes: CLAUDE_FAKES });
    const repo = await makeGitRepo(env.root);
    const { output } = await runCommand(env.ctx, ["spawn", "--goal", "Fix it", "--repo", repo]);
    expect(JSON.parse(output)).toMatchObject({
        harness: "claude",
        model: "opus",
        effort: "high",
        autonomy: "auto",
    });
});

test("the spawn command rejects an unknown --autonomy", async () => {
    env = testContext();
    await expect(
        runCommand(env.ctx, ["spawn", "--goal", "x", "--autonomy", "yolo"]),
    ).rejects.toThrow(/autonomy/);
});
