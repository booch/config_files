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
    const path = transcriptPath(
        env.ctx.claudeHome,
        record.worktree,
        record.harness_session_id as string,
    );
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

test("is unavailable while the harness session id is unknown", async () => {
    env = testContext();
    await addSession(env.ctx, sampleRecord({ harness_session_id: null }));
    expect(await digestSession(env.ctx, "chief-cli")).toMatchObject({
        available: false,
        transcript: null,
    });
});
