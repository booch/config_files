import { describe, expect, test } from "bun:test";
import { kickoffPrompt, slugify, validateSlug } from "../src/kickoff";

describe("slugify", () => {
    test("lowercases and hyphenates", () => {
        expect(slugify("Implement chief spawn + registry!")).toBe("implement-chief-spawn-registry");
    });
    test("caps length at 40 without a trailing hyphen", () => {
        const slug = slugify(`${"a".repeat(39)} bcd`);
        expect(slug.length).toBeLessThanOrEqual(40);
        expect(slug.endsWith("-")).toBe(false);
    });
    test("rejects text with nothing usable", () => {
        expect(() => slugify("!!!")).toThrow(/--slug/);
    });
});

describe("validateSlug", () => {
    test("accepts a plain slug", () => expect(validateSlug("chief-cli")).toBe("chief-cli"));
    test.each(["../escape", "has space", "UPPER", "-leading", "a/b", ""])("rejects %p", (bad) => {
        expect(() => validateSlug(bad)).toThrow();
    });
});

describe("kickoffPrompt", () => {
    const base = {
        id: "0190-id",
        slug: "chief-cli",
        goal: "Build it",
        chief: "bun '/opt/chief/src/cli.ts'",
    };

    test("states the goal, the session id, and exact report commands", () => {
        const prompt = kickoffPrompt({ ...base, autonomy: "auto" });
        expect(prompt).toContain("Build it");
        expect(prompt).toContain(
            "bun '/opt/chief/src/cli.ts' report 0190-id --state waiting --waiting-on",
        );
        expect(prompt).toContain("bun '/opt/chief/src/cli.ts' report 0190-id --state done");
    });

    test("auto mode grants continue-without-prompting but keeps the always-escalate list", () => {
        const prompt = kickoffPrompt({ ...base, autonomy: "auto" });
        expect(prompt).toContain("continue without prompting");
        for (const item of ["push", "pull request", "destructive", "scope"])
            expect(prompt).toContain(item);
    });

    test("checkpointed mode adds checkpoints after the plan and the tests", () => {
        const prompt = kickoffPrompt({ ...base, autonomy: "checkpointed" });
        expect(prompt).toContain("approve-plan");
        expect(prompt).toContain("approve-tests");
    });
});
