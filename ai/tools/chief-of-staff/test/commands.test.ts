import { afterEach, describe, expect, test } from "bun:test";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runCommand } from "../src/commands";
import { addSession, loadRegistry } from "../src/registry";
import { CLOSED_AT, sampleRecord, testContext } from "./helpers";

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

    test("writes the config template once, never overwriting edits", async () => {
        env = testContext();
        await run("init");
        writeFileSync(join(env.ctx.home, "config.toml"), "# mine\n");
        await run("init");
        expect(readFileSync(join(env.ctx.home, "config.toml"), "utf8")).toBe("# mine\n");
    });
});

describe("list", () => {
    test("shows active sessions, one line each", async () => {
        env = testContext();
        await addSession(
            env.ctx,
            sampleRecord({ id: "a1", slug: "live", state: "waiting", waiting_on: "approve-tests" }),
        );
        await addSession(
            env.ctx,
            sampleRecord({ id: "b2", slug: "old", state: "done", closed_at: CLOSED_AT }),
        );
        const { output } = await run("list");
        expect(output).toContain("live");
        expect(output).toContain("waiting on approve-tests");
        expect(output).not.toContain("old");
    });

    test("keeps a worker's done session listed until the human closes it", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ state: "done", summary: "ready to merge" }));
        expect((await run("list")).output).toContain("ready to merge");
    });

    test("--all includes closed sessions; --json emits records", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ state: "done", closed_at: CLOSED_AT }));
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
    expect(readFileSync(join(env.ctx.home, "journal", "2026-09.md"), "utf8")).toContain(
        "- 14:02 decided not to escalate",
    );
});

describe("close", () => {
    test("marks done with a summary and journals it", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await run("close", "chief-cli", "--summary", "merged");
        const [record] = await loadRegistry(env.ctx);
        expect(record).toMatchObject({
            state: "done",
            summary: "merged",
            closed_at: "2026-09-23T14:02:00.000Z",
        });
        expect(readFileSync(join(env.ctx.home, "journal", "2026-09.md"), "utf8")).toContain(
            "closed `chief-cli` (done): merged",
        );
    });

    test("--abandon marks abandoned", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await run("close", "chief-cli", "--abandon");
        expect((await loadRegistry(env.ctx))[0]?.state).toBe("abandoned");
    });

    test("refuses to close a session twice", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ state: "done", closed_at: CLOSED_AT }));
        await expect(run("close", "chief-cli", "--abandon")).rejects.toThrow(/already closed/);
        expect((await loadRegistry(env.ctx))[0]?.state).toBe("done");
    });
});

test("unknown commands and missing arguments are usage errors", async () => {
    env = testContext();
    await expect(run("bogus")).rejects.toThrow(/usage/i);
    await expect(run("status")).rejects.toThrow(/usage/i);
});

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
