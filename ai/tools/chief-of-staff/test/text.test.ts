import { expect, test } from "bun:test";
import { homedir } from "node:os";
import { expandHome, firstLine, oneLine, shellQuote, truncate } from "../src/text";

test("oneLine collapses newlines and runs of whitespace", () => {
    expect(oneLine("  a\n\n## b\t c ")).toBe("a ## b c");
});

test("truncate adds an ellipsis only when it cuts", () => {
    expect(truncate("short", 10)).toBe("short");
    expect(truncate("0123456789abc", 10)).toBe("012345678…");
});

test("firstLine returns the first non-blank line, trimmed", () => {
    expect(firstLine("\n  error: boom \nmore")).toBe("error: boom");
    expect(firstLine("")).toBe("");
});

test("shellQuote survives single quotes and spaces", () => {
    expect(shellQuote("/a b/it's")).toBe(`'/a b/it'\\''s'`);
});

test("expandHome expands only a leading ~/", () => {
    expect(expandHome("~/x")).toBe(`${homedir()}/x`);
    expect(expandHome("/a/~/x")).toBe("/a/~/x");
});
