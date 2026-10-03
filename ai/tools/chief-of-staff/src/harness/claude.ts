import { join } from "node:path";
import { KICKOFF_FILE } from "../kickoff";
import { shellQuote } from "../text";

const KICKOFF_INSTRUCTION = `Read ${KICKOFF_FILE} in the current directory and follow it.`;
const HOOK_TIMEOUT_SECONDS = 30;

export interface LaunchSpec {
    slug: string;
    model: string;
    effort: string;
    settingsPath: string;
}

export function launchArgv({ slug, model, effort, settingsPath }: LaunchSpec): string[] {
    return [
        "claude",
        "--bg",
        "--name",
        slug,
        "--model",
        model,
        "--effort",
        effort,
        "--permission-mode",
        "auto",
        "--settings",
        settingsPath,
        KICKOFF_INSTRUCTION,
    ];
}

export function resumeArgv(sessionId: string, message: string): string[] {
    return ["claude", "--bg", "--resume", sessionId, message];
}

export const AGENTS_ARGV = ["claude", "agents", "--json"];

export function stopArgv(ref: string): string[] {
    return ["claude", "stop", ref];
}

// Matches the real `claude --bg` output (test/fixtures/claude-bg-output.txt).
export function parseBgRef(stdout: string): string | null {
    const match = stdout.match(/claude attach (\S+)/);
    return match?.[1] ?? null;
}

interface AgentEntry {
    id?: unknown;
    sessionId?: unknown;
}

// `claude agents --json` maps the short id that `--bg` prints to the full session id.
export function sessionIdFor(agentsJson: string, ref: string): string | null {
    const match = parseAgents(agentsJson).find((agent) => agent.id === ref);
    return typeof match?.sessionId === "string" ? match.sessionId : null;
}

// A listed session still has a live process, even when idle.
export function isListed(agentsJson: string, ref: string): boolean {
    return parseAgents(agentsJson).some((agent) => agent.id === ref);
}

function parseAgents(json: string): AgentEntry[] {
    try {
        const parsed = JSON.parse(json);
        return Array.isArray(parsed) ? parsed : [];
    } catch {
        return [];
    }
}

export function stopHookSettings(command: string) {
    return {
        hooks: { Stop: [{ hooks: [{ type: "command", command, timeout: HOOK_TIMEOUT_SECONDS }] }] },
    };
}

export function attachCommands(sessionId: string | null, ref: string | null, worktree: string) {
    return {
        terminal: ref ? `claude attach ${ref}` : null,
        resume: sessionId ? `cd ${shellQuote(worktree)} && claude --resume ${sessionId}` : null,
    };
}

export function transcriptPath(claudeHome: string, worktree: string, sessionId: string): string {
    return join(
        claudeHome,
        "projects",
        worktree.replace(/[^a-zA-Z0-9]/g, "-"),
        `${sessionId}.jsonl`,
    );
}

export interface TranscriptDigest {
    lastActivityAt: string | null;
    textMessages: number;
    toolCalls: number;
    recentMessages: string[];
}

// Transcript entries are external JSON; type only what we read, and narrow before use.
interface TranscriptEntry {
    type?: unknown;
    timestamp?: unknown;
    message?: { content?: unknown };
}

interface ContentBlock {
    type?: string;
    text?: string;
}

export function digestTranscript(jsonl: string, recent = 3): TranscriptDigest {
    let lastActivityAt: string | null = null;
    let toolCalls = 0;
    const texts: string[] = [];
    for (const entry of parseLines(jsonl)) {
        if (entry.type !== "user" && entry.type !== "assistant") continue;
        if (typeof entry.timestamp === "string") lastActivityAt = entry.timestamp;
        if (entry.type !== "assistant" || !Array.isArray(entry.message?.content)) continue;
        for (const block of entry.message.content as ContentBlock[]) {
            if (block.type === "tool_use") toolCalls++;
            if (block.type === "text" && block.text?.trim()) texts.push(block.text.trim());
        }
    }
    return {
        lastActivityAt,
        textMessages: texts.length,
        toolCalls,
        recentMessages: texts.slice(-recent),
    };
}

// A transcript being written can end mid-line; skip what does not parse.
function parseLines(jsonl: string): TranscriptEntry[] {
    return jsonl.split("\n").flatMap((line) => {
        if (!line.trim()) return [];
        try {
            return [JSON.parse(line) as TranscriptEntry];
        } catch {
            return [];
        }
    });
}
