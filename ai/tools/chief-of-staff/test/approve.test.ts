import { afterEach, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { approveSession } from "../src/approve";
import { runCommand } from "../src/commands";
import type { Context } from "../src/context";
import { addSession, loadRegistry } from "../src/registry";
import { sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const waiting = sampleRecord({ state: "waiting", waiting_on: "approve-tests" });

test("stops the session, then resumes it in the background with the message, in its worktree", async () => {
    env = testContext();
    await addSession(env.ctx, waiting);
    await approveSession(env.ctx, "chief-cli", "Tests look good; implement.");
    expect(env.calls).toEqual([
        { argv: ["claude", "stop", "5f3a9c00"] },
        { argv: ["claude", "agents", "--json"] },
        {
            argv: [
                "claude",
                "--bg",
                "--resume",
                "5f3a9c00-1111-4222-8333-444455556666",
                "Tests look good; implement.",
            ],
            cwd: waiting.worktree,
        },
    ]);
});

test("waits for the stopped session to disappear before resuming", async () => {
    let polls = 0;
    env = testContext();
    const listed = JSON.stringify([{ id: "5f3a9c00" }]);
    const ctx: Context = {
        ...env.ctx,
        run: async (argv, options) =>
            argv[1] === "agents"
                ? { exitCode: 0, stdout: ++polls < 3 ? listed : "[]", stderr: "" }
                : env.ctx.run(argv, options),
    };
    await addSession(ctx, waiting);
    await approveSession(ctx, "chief-cli");
    expect(polls).toBe(3);
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

test("refuses when the Claude session id is unknown", async () => {
    env = testContext();
    await addSession(
        env.ctx,
        sampleRecord({ state: "waiting", waiting_on: "x", harness_session_id: null }),
    );
    await expect(approveSession(env.ctx, "chief-cli")).rejects.toThrow(/no Claude session id/);
    expect(env.calls).toEqual([]);
});

test("leaves the record untouched when the resume fails", async () => {
    env = testContext({ fakes: { "claude --bg": { exitCode: 1, stderr: "no such session" } } });
    await addSession(env.ctx, waiting);
    await expect(approveSession(env.ctx, "chief-cli")).rejects.toThrow(/no such session/);
    expect((await loadRegistry(env.ctx))[0]?.state).toBe("waiting");
});

test("the approve command joins remaining words into the message", async () => {
    env = testContext();
    await addSession(env.ctx, waiting);
    await runCommand(env.ctx, ["approve", "chief-cli", "ship", "it"]);
    expect(env.calls.at(-1)?.argv.at(-1)).toBe("ship it");
});
