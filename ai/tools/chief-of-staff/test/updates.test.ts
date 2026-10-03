import { afterEach, expect, test } from "bun:test";
import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { highlights, markReviewed, unreviewedUpdates } from "../src/updates";
import { testContext, watchReports } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

function setup() {
    env = testContext();
    const dirs = watchReports(env, {
        "mac-software-updates": {
            "2026-09-21": "# Updates\n\n- 6 upgrades, nothing notable\n",
            "2026-09-22": "# Updates\n\n- 14 upgrades\n- jj 0.32→0.33 (breaking)\n",
        },
        "workflow-retro": { "2026-09-21": "3 friction items\n" },
        missing: {},
    });
    const brew = dirs["mac-software-updates"] as string;
    writeFileSync(join(brew, "notes.txt"), "ignored: not a dated file");
    return { brew };
}

test("lists dated reports from every watched dir, newest first, skipping missing dirs", async () => {
    const { brew } = setup();
    const updates = await unreviewedUpdates(env.ctx);
    expect(updates.map((u) => [u.task, u.date])).toEqual([
        ["mac-software-updates", "2026-09-22"],
        ["mac-software-updates", "2026-09-21"],
        ["workflow-retro", "2026-09-21"],
    ]);
    expect(updates[0]).toMatchObject({
        path: join(brew, "2026-09-22.md"),
        highlights: ["14 upgrades", "jj 0.32→0.33 (breaking)"],
    });
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

test("a corrupt reviewed.json is reported by name, not guessed at", async () => {
    setup();
    writeFileSync(join(env.ctx.home, "reviewed.json"), "{bad");
    await expect(unreviewedUpdates(env.ctx)).rejects.toThrow(/reviewed\.json/);
});

test("an empty reviewed.json is reported by name, like any unparseable file", async () => {
    setup();
    writeFileSync(join(env.ctx.home, "reviewed.json"), "");
    await expect(unreviewedUpdates(env.ctx)).rejects.toThrow(/reviewed\.json is not valid JSON/);
});

test("a reviewed.json that is not an object is reported by name", async () => {
    setup();
    writeFileSync(join(env.ctx.home, "reviewed.json"), "[]");
    await expect(unreviewedUpdates(env.ctx)).rejects.toThrow(/reviewed\.json/);
});

test("highlights skip headings, frontmatter fences, and bullet markers", () => {
    expect(highlights("---\n# Title\n\n* one\n- two\nthree\nfour\n")).toEqual([
        "one",
        "two",
        "three",
    ]);
});
