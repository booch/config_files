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
    writeQuota(
        JSON.stringify({
            five_hour: { used_percentage: 24, resets_at: 1789791600 },
            seven_day: { used_percentage: 61, resets_at: 1790000000 },
            updated_at: "2026-09-23T13:00:00Z",
        }),
    );
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
    writeQuota("null");
    expect(await readQuota(env.ctx)).toBeNull();
});

test("a reset time no date can hold is null, not an error", async () => {
    env = testContext();
    writeQuota(JSON.stringify({ five_hour: { used_percentage: 24, resets_at: 1e20 } }));
    expect(await readQuota(env.ctx)).toMatchObject({
        five_hour_percent: 24,
        five_hour_resets_at: null,
    });
});
