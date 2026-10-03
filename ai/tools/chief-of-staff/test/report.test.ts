import { afterEach, describe, expect, test } from "bun:test";
import { runCommand } from "../src/commands";
import { addSession, loadRegistry } from "../src/registry";
import { reportState, reportStopped, UNREPORTED_STOP } from "../src/report";
import { readJournal, sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const stored = async () => (await loadRegistry(env.ctx))[0];

describe("reportState", () => {
    test("waiting records the checkpoint, summary, and activity time, and journals it", async () => {
        env = testContext({ now: "2026-09-23T14:40:00Z" });
        await addSession(env.ctx, sampleRecord());
        await reportState(env.ctx, "chief-cli", {
            state: "waiting",
            waitingOn: "approve-tests",
            summary: "tests written",
        });
        expect(await stored()).toMatchObject({
            state: "waiting",
            waiting_on: "approve-tests",
            summary: "tests written",
            last_activity_at: "2026-09-23T14:40:00.000Z",
        });
        expect(readJournal(env.ctx)).toContain(
            "- 14:40 `chief-cli` waiting on approve-tests: tests written",
        );
    });

    test("waiting requires a checkpoint name", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await expect(reportState(env.ctx, "chief-cli", { state: "waiting" })).rejects.toThrow(
            /--waiting-on/,
        );
    });

    test("leaving waiting clears waiting_on and keeps the old summary if none is given", async () => {
        env = testContext();
        await addSession(
            env.ctx,
            sampleRecord({ state: "waiting", waiting_on: "x", summary: "kept" }),
        );
        await reportState(env.ctx, "chief-cli", { state: "running" });
        expect(await stored()).toMatchObject({
            state: "running",
            waiting_on: null,
            summary: "kept",
        });
    });
});

describe("reportStopped (Stop hook)", () => {
    test("a stop while still running means the worker is waiting on the human", async () => {
        env = testContext({ now: "2026-09-23T15:00:00Z" });
        await addSession(env.ctx, sampleRecord());
        await reportStopped(
            env.ctx,
            "chief-cli",
            JSON.stringify({ last_assistant_message: "Which DB should I use?\nThanks" }),
        );
        expect(await stored()).toMatchObject({
            state: "waiting",
            waiting_on: UNREPORTED_STOP,
            summary: "Which DB should I use? Thanks",
            last_activity_at: "2026-09-23T15:00:00.000Z",
        });
        expect(readJournal(env.ctx)).toContain("`chief-cli` stopped without reporting");
    });

    test("after an explicit report, a stop only refreshes activity", async () => {
        env = testContext({ now: "2026-09-23T15:00:00Z" });
        await addSession(env.ctx, sampleRecord({ state: "done", summary: "merged" }));
        await reportStopped(env.ctx, "chief-cli", "{}");
        expect(await stored()).toMatchObject({
            state: "done",
            summary: "merged",
            last_activity_at: "2026-09-23T15:00:00.000Z",
        });
    });

    test("still records a stop when another Stop hook blocked the previous one", async () => {
        env = testContext({ now: "2026-09-23T15:00:00Z" });
        await addSession(env.ctx, sampleRecord());
        await reportStopped(env.ctx, "chief-cli", JSON.stringify({ stop_hook_active: true }));
        expect(await stored()).toMatchObject({
            state: "waiting",
            waiting_on: UNREPORTED_STOP,
            last_activity_at: "2026-09-23T15:00:00.000Z",
        });
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
        await reportStopped(
            env.ctx,
            "chief-cli",
            JSON.stringify({ last_assistant_message: "x".repeat(500) }),
        );
        expect((await stored())?.summary?.length).toBe(200);
    });

    test("fills in the harness session id from the hook input when spawn could not", async () => {
        env = testContext();
        await addSession(
            env.ctx,
            sampleRecord({ harness_session_id: null, attach: { terminal: null, resume: null } }),
        );
        await reportStopped(
            env.ctx,
            "chief-cli",
            JSON.stringify({ session_id: "full-session-id" }),
        );
        expect(await stored()).toMatchObject({
            harness_session_id: "full-session-id",
            attach: {
                resume: "cd '/worktrees/repo/chief-cli' && claude --resume full-session-id",
            },
        });
    });

    test("never overwrites a known harness session id", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await reportStopped(env.ctx, "chief-cli", JSON.stringify({ session_id: "other" }));
        expect((await stored())?.harness_session_id).toBe(sampleRecord().harness_session_id);
    });
});

describe("report command", () => {
    test("explicit mode parses flags", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await runCommand(env.ctx, [
            "report",
            "chief-cli",
            "--state",
            "done",
            "--summary",
            "shipped",
        ]);
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
        await expect(runCommand(env.ctx, ["report", "x", "--state", "napping"])).rejects.toThrow(
            /--state must be one of/,
        );
    });
});
