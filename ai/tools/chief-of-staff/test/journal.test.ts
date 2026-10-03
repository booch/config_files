import { afterEach, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { appendJournal, tailJournal } from "../src/journal";
import { testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const journalFile = (month: string) =>
    readFileSync(join(env.ctx.home, "journal", `${month}.md`), "utf8");

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
    expect(await tailJournal(env.ctx, 3)).toEqual([
        "- 23:00 august",
        "## 2026-09-01",
        "- 08:00 september",
    ]);
});

test("tail is empty before anything is journaled", async () => {
    env = testContext();
    expect(await tailJournal(env.ctx, 5)).toEqual([]);
});
