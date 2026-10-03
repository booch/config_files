import { afterEach, expect, test } from "bun:test";
import { mkdirSync, utimesSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
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
    await addSession(
        env.ctx,
        sampleRecord({ id: "r1", slug: "fresh", last_activity_at: "2026-09-26T13:40:00.000Z" }),
    );
    await addSession(
        env.ctx,
        sampleRecord({ id: "r2", slug: "stale", last_activity_at: "2026-09-23T14:00:00.000Z" }),
    );
    await addSession(
        env.ctx,
        sampleRecord({
            id: "w1",
            slug: "needs-you",
            state: "waiting",
            waiting_on: "approve-tests",
        }),
    );
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
    const path = transcriptPath(
        env.ctx.claudeHome,
        record.worktree,
        record.harness_session_id as string,
    );
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

test("includes unreviewed scheduled-task updates", async () => {
    env = testContext({ now: NOW });
    const dir = join(env.root, "mac-software-updates");
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "2026-09-26.md"), "- 3 upgrades\n");
    writeFileSync(join(env.ctx.home, "config.toml"), `[watch]\ndirs = ["${dir}"]\n`);
    expect((await buildBriefing(env.ctx)).updates.map((u) => u.date)).toEqual(["2026-09-26"]);
});
