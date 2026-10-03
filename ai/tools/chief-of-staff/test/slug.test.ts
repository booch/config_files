import { describe, expect, test } from "bun:test";
import { slugify, validateSlug } from "../src/slug";

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
