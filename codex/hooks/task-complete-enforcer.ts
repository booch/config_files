#!/usr/bin/env -S bun run
import { readFileSync, existsSync, mkdirSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

const MARKER_RE = /\[\[\s*task-complete\s*\]\]|<task-complete\s*\/?\s*>/i;
const FALLBACK_PHRASES: RegExp[] = [
  /\btask\s+complete(?:d|ly)?\b/i,
  /\ball\s+done\b/i,
  /\bready\s+to\s+commit\b/i,
  /\ball\s+tests?\s+pass(?:ing)?\b/i,
  /\bwork\s+is\s+finished\b/i,
];
const EDIT_TOOLS = new Set(["apply_patch"]);
const RETRO = { edits: 3, files: 3, durationMs: 10 * 60 * 1000 };

type Scope = {
  editWriteCount: number;
  filesModified: Set<string>;
  durationMs: number;
  textCorpus: string;
};

type Requirement = { skill: string; reason: string };

async function main(): Promise<void> {
  const input = await readJsonStdin();
  if (input.stop_hook_active === true) return;

  const last = String(input.last_assistant_message ?? "");
  const hasMarker = MARKER_RE.test(last);
  const hasPhrase = !hasMarker && FALLBACK_PHRASES.some((re) => re.test(last));
  if (!hasMarker && !hasPhrase) return;

  const scope = analyseTranscript(input.transcript_path as string | undefined);
  const missing = computeMissing(scope);
  if (missing.length === 0) return;

  const sessionId = typeof input.session_id === "string" ? input.session_id : undefined;
  if (reminderAlreadyDelivered(sessionId, missing)) return;

  const reasonLines: string[] = [];
  reasonLines.push(
    `\`<task-complete/>\`${hasPhrase ? " (via fallback phrase — prefer the explicit marker)" : ""} emitted but required completion skills were not invoked this task:`,
  );
  for (const m of missing) reasonLines.push(`  - \`${m.skill}\` — ${m.reason}`);
  reasonLines.push("", "Invoke each before re-emitting — for example:");
  for (const m of missing) reasonLines.push(`  $${m.skill}`);
  reasonLines.push("", "Then re-emit `[[task-complete]]` on its own line.");
  process.stdout.write(JSON.stringify({ decision: "block", reason: reasonLines.join("\n") }));
}

function analyseTranscript(path?: string): Scope {
  const empty: Scope = { editWriteCount: 0, filesModified: new Set(), durationMs: 0, textCorpus: "" };
  if (!path || !existsSync(path)) return empty;

  const entries = readFileSync(path, "utf8")
    .split("\n")
    .filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } })
    .filter((x) => x !== null);

  const scopeStart = findScopeStart(entries);
  const inScope = entries.slice(scopeStart);

  let editWriteCount = 0;
  const filesModified = new Set<string>();
  const timestamps: number[] = [];
  const textPieces: string[] = [];
  for (const e of inScope) {
    if (typeof e.timestamp === "string") {
      const ms = Date.parse(e.timestamp);
      if (!Number.isNaN(ms)) timestamps.push(ms);
    }
    if (e.type !== "response_item") continue;
    const p = e.payload;
    if (p?.type === "function_call" && EDIT_TOOLS.has(p.name)) {
      editWriteCount++;
      const fp = extractFilePath(p.arguments);
      if (fp) filesModified.add(fp);
    } else if (p?.type === "message") {
      for (const c of p.content ?? []) {
        if (typeof c.text === "string") textPieces.push(c.text);
      }
    }
  }

  const durationMs = timestamps.length >= 2 ? Math.max(...timestamps) - Math.min(...timestamps) : 0;
  return { editWriteCount, filesModified, durationMs, textCorpus: textPieces.join("\n") };
}

function findScopeStart(entries: any[]): number {
  let lastAssistantSeen = -1;
  for (let i = entries.length - 1; i >= 0; i--) {
    const e = entries[i];
    if (e?.type !== "response_item" || e?.payload?.type !== "message" || e?.payload?.role !== "assistant") continue;
    if (lastAssistantSeen < 0) { lastAssistantSeen = i; continue; }
    const text = (e.payload.content ?? []).map((c: any) => c?.text ?? "").join("");
    if (MARKER_RE.test(text)) return i + 1;
  }
  return 0;
}

function extractFilePath(rawArgs: unknown): string | null {
  if (typeof rawArgs !== "string") return null;
  try {
    const args = JSON.parse(rawArgs);
    const fp = args.file_path ?? args.path ?? args.filename;
    return typeof fp === "string" && fp ? fp : null;
  } catch {
    return null;
  }
}

function computeMissing(scope: Scope): Requirement[] {
  const req: Requirement[] = [];
  if (scope.editWriteCount > 0) {
    req.push({ skill: "pre-commit", reason: "Edit/Write ran this task" });
    req.push({ skill: "boochtek:documentation", reason: "Edit/Write ran this task" });
  }
  if (
    scope.editWriteCount >= RETRO.edits ||
    scope.filesModified.size >= RETRO.files ||
    scope.durationMs >= RETRO.durationMs
  ) {
    req.push({ skill: "retro", reason: "task crossed effort threshold" });
  }
  return req.filter((r) => !invokedInCorpus(r.skill, scope.textCorpus));
}

function invokedInCorpus(skill: string, corpus: string): boolean {
  const bare = skill.split(":").pop()!;
  for (const name of new Set([skill, bare])) {
    const re = new RegExp(`(?:\\$|\\/|@)${escapeRegex(name)}\\b`, "i");
    if (re.test(corpus)) return true;
  }
  return false;
}

function escapeRegex(s: string): string {
  return s.replace(/[\\^$.*+?()[\]{}|]/g, "\\$&");
}

// Block at most once per session per distinct missing-skill set. A blocking Stop re-invokes
// the model, and the condition persists until it acts — so without this guard the same block
// fires endlessly. Recording the fingerprint lets later identical Stops pass through.
// `stop_hook_active` remains the backstop for runaway loops.
function reminderAlreadyDelivered(sessionId: string | undefined, missing: Requirement[]): boolean {
  const file = stateFile(sessionId);
  const fingerprint = missing.map((m) => m.skill).sort().join(",");
  try {
    const delivered = existsSync(file) ? readFileSync(file, "utf8").split("\n") : [];
    if (delivered.includes(fingerprint)) return true;
    mkdirSync(dirname(file), { recursive: true });
    appendFileSync(file, `${fingerprint}\n`);
  } catch {
    // Fail open: never silently drop a first reminder.
  }
  return false;
}

function stateFile(sessionId: string | undefined): string {
  const cacheHome = process.env.XDG_CACHE_HOME || join(homedir(), ".cache");
  const id = (sessionId || "unknown-session").replace(/[^A-Za-z0-9_-]/g, "_");
  return join(cacheHome, "claude-hooks", "task-complete-enforcer", `${id}.txt`);
}

async function readJsonStdin(): Promise<Record<string, unknown>> {
  try {
    const chunks: Buffer[] = [];
    for await (const chunk of process.stdin) chunks.push(chunk as Buffer);
    return JSON.parse(Buffer.concat(chunks).toString("utf8")) as Record<string, unknown>;
  } catch {
    return {};
  }
}

main().catch((e) => {
  process.stderr.write(`codex task-complete-enforcer error: ${e?.message ?? e}\n`);
  process.exit(0);
});
