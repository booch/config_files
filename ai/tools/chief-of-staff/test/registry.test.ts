import { afterEach, describe, expect, test } from "bun:test";
import { mkdirSync, readdirSync, utimesSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { ChiefError } from "../src/context";
import { addSession, findSession, isActive, loadRegistry, updateSession } from "../src/registry";
import { CLOSED_AT, sampleRecord, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

describe("loadRegistry", () => {
    test("is empty when no registry file exists yet", async () => {
        env = testContext();
        expect(await loadRegistry(env.ctx)).toEqual([]);
    });

    test("refuses to guess when the file is corrupt, naming the file", async () => {
        env = testContext();
        writeFileSync(join(env.ctx.home, "registry.json"), "{not json");
        await expect(loadRegistry(env.ctx)).rejects.toThrow(/registry\.json/);
    });

    for (const content of ["{}", "null"]) {
        test(`refuses a file without a sessions list (${content}), naming the file`, async () => {
            env = testContext();
            writeFileSync(join(env.ctx.home, "registry.json"), content);
            const loading = loadRegistry(env.ctx);
            await expect(loading).rejects.toThrow(ChiefError);
            await expect(loading).rejects.toThrow(/registry\.json/);
        });
    }
});

describe("addSession", () => {
    test("persists the record", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        expect(await loadRegistry(env.ctx)).toEqual([sampleRecord()]);
    });

    test("leaves no temp or lock files behind", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        expect(readdirSync(env.ctx.home)).toEqual(["registry.json"]);
    });

    test("loses no records when many writers race", async () => {
        env = testContext();
        const ids = Array.from({ length: 20 }, (_, i) => `id-${i}`);
        await Promise.all(ids.map((id) => addSession(env.ctx, sampleRecord({ id, slug: id }))));
        const stored = (await loadRegistry(env.ctx)).map((s) => s.id).sort();
        expect(stored).toEqual([...ids].sort());
    });

    test("breaks a lock left by a crashed process", async () => {
        env = testContext();
        const lock = join(env.ctx.home, "registry.lock");
        mkdirSync(lock);
        const thirtyOneSecondsAgo = new Date(Date.now() - 31_000);
        utimesSync(lock, thirtyOneSecondsAgo, thirtyOneSecondsAgo);
        await addSession(env.ctx, sampleRecord());
        expect(readdirSync(env.ctx.home)).toEqual(["registry.json"]);
    });

    test("rejects a duplicate id", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        await expect(addSession(env.ctx, sampleRecord())).rejects.toThrow(ChiefError);
    });
});

describe("updateSession", () => {
    test("applies the change and returns the updated record", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        const updated = await updateSession(env.ctx, sampleRecord().id, () => ({ state: "done" }));
        expect(updated.state).toBe("done");
        expect((await loadRegistry(env.ctx))[0]?.state).toBe("done");
    });

    test("hands the change function the current record", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ summary: "before" }));
        await updateSession(env.ctx, sampleRecord().id, (s) => ({ summary: `${s.summary}+after` }));
        expect((await loadRegistry(env.ctx))[0]?.summary).toBe("before+after");
    });

    test("never lets a change rewrite the id", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord());
        const updated = await updateSession(env.ctx, sampleRecord().id, () => ({ id: "other" }));
        expect(updated.id).toBe(sampleRecord().id);
    });

    test("throws for an unknown id", async () => {
        env = testContext();
        await expect(updateSession(env.ctx, "nope", () => ({}))).rejects.toThrow(ChiefError);
    });
});

describe("findSession", () => {
    const first = sampleRecord({
        id: "0190aaaa-0000-7000-8000-000000000001",
        slug: "alpha",
        state: "done",
        closed_at: CLOSED_AT,
    });
    const second = sampleRecord({ id: "0190bbbb-0000-7000-8000-000000000002", slug: "alpha" });

    test("finds by full id, unique prefix, or slug (latest wins)", async () => {
        env = testContext();
        await addSession(env.ctx, first);
        await addSession(env.ctx, second);
        expect((await findSession(env.ctx, first.id)).id).toBe(first.id);
        expect((await findSession(env.ctx, "0190aa")).id).toBe(first.id);
        expect((await findSession(env.ctx, "alpha")).id).toBe(second.id);
    });

    test("finds by the harness's short id, the one `claude attach` shows", async () => {
        env = testContext();
        await addSession(env.ctx, sampleRecord({ ...first, harness_ref: "ab12cd34" }));
        await addSession(env.ctx, sampleRecord({ ...second, slug: "ab12cd34" }));
        expect((await findSession(env.ctx, "ab12cd34")).id).toBe(first.id);
    });

    test("rejects ambiguous or too-short prefixes, and unknown refs", async () => {
        env = testContext();
        await addSession(env.ctx, first);
        await addSession(env.ctx, second);
        await expect(findSession(env.ctx, "0190")).rejects.toThrow(/ambiguous/);
        await expect(findSession(env.ctx, "019")).rejects.toThrow(ChiefError);
        await expect(findSession(env.ctx, "missing")).rejects.toThrow(/no session/);
    });
});

test("a session stays active, even when done, until the human closes it", () => {
    expect(isActive(sampleRecord({ state: "waiting" }))).toBe(true);
    expect(isActive(sampleRecord({ state: "done" }))).toBe(true);
    expect(isActive(sampleRecord({ state: "done", closed_at: CLOSED_AT }))).toBe(false);
    expect(isActive(sampleRecord({ state: "abandoned", closed_at: CLOSED_AT }))).toBe(false);
});
