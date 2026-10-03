import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
    attachCommands,
    digestTranscript,
    isListed,
    launchArgv,
    parseBgRef,
    resumeArgv,
    sessionIdFor,
    stopArgv,
    stopHookSettings,
    transcriptPath,
} from "../src/harness/claude";

const fixture = (name: string) => readFileSync(join(import.meta.dir, "fixtures", name), "utf8");

test("launchArgv starts a named background session with our model, effort, and hooks", () => {
    expect(
        launchArgv({ slug: "s", model: "opus", effort: "high", settingsPath: "/h.json" }),
    ).toEqual([
        "claude",
        "--bg",
        "--name",
        "s",
        "--model",
        "opus",
        "--effort",
        "high",
        "--permission-mode",
        "auto",
        "--settings",
        "/h.json",
        "Read .chief-kickoff.md in the current directory and follow it.",
    ]);
});

test("resumeArgv continues the same session in the background", () => {
    expect(resumeArgv("U", "Approved.")).toEqual(["claude", "--bg", "--resume", "U", "Approved."]);
});

describe("parseBgRef", () => {
    test("reads the short id from real `claude --bg` output (spike fixture)", () => {
        expect(parseBgRef(fixture("claude-bg-output.txt"))).toBe("ca42e85d");
    });
    test("returns null when the output has no id", () => {
        expect(parseBgRef("something unexpected")).toBeNull();
    });
});

test("stopHookSettings registers one Stop command", () => {
    expect(stopHookSettings("chief report U --stopped")).toEqual({
        hooks: {
            Stop: [
                { hooks: [{ type: "command", command: "chief report U --stopped", timeout: 30 }] },
            ],
        },
    });
});

test("attachCommands offers each command only when its id is known", () => {
    expect(attachCommands("S", "ab12", "/w t")).toEqual({
        terminal: "claude attach ab12",
        resume: "cd '/w t' && claude --resume S",
    });
    expect(attachCommands(null, null, "/w")).toEqual({ terminal: null, resume: null });
});

describe("claude agents --json", () => {
    const agents = JSON.stringify([
        { id: "ca42e85d", sessionId: "ca42e85d-bc19-44c5-8a7a-244064a4c0e5", state: "done" },
    ]);

    test("sessionIdFor maps a short id to the full session id", () => {
        expect(sessionIdFor(agents, "ca42e85d")).toBe("ca42e85d-bc19-44c5-8a7a-244064a4c0e5");
        expect(sessionIdFor(agents, "nope")).toBeNull();
        expect(sessionIdFor("not json", "ca42e85d")).toBeNull();
    });

    test("isListed says whether the session's process still exists", () => {
        expect(isListed(agents, "ca42e85d")).toBe(true);
        expect(isListed("[]", "ca42e85d")).toBe(false);
    });
});

test("stopArgv stops a background session by short id", () => {
    expect(stopArgv("ab12")).toEqual(["claude", "stop", "ab12"]);
});

test("transcriptPath mirrors Claude's project-directory naming", () => {
    expect(transcriptPath("/c", "/Users/me/.local/share/ai/worktrees/.config/x", "U")).toBe(
        "/c/projects/-Users-me--local-share-ai-worktrees--config-x/U.jsonl",
    );
});

describe("digestTranscript", () => {
    const digest = digestTranscript(fixture("claude-transcript.jsonl"), 2);

    test("takes last activity from user and assistant entries only", () => {
        expect(digest.lastActivityAt).toBe("2026-09-23T14:40:00.000Z");
    });
    test("counts tool calls and text messages", () => {
        expect(digest.toolCalls).toBe(2);
        expect(digest.textMessages).toBe(2);
    });
    test("keeps the most recent text messages, oldest first", () => {
        expect(digest.recentMessages).toEqual([
            "Wrote the registry tests.",
            "Tests written; waiting for review.",
        ]);
    });
    test("an empty transcript has no activity", () => {
        expect(digestTranscript("")).toEqual({
            lastActivityAt: null,
            textMessages: 0,
            toolCalls: 0,
            recentMessages: [],
        });
    });
});
