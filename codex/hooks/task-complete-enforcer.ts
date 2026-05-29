#!/usr/bin/env -S bun run
import { readFileSync, existsSync } from "node:fs";

const MARKER_RE = /<task-complete\s*\/?\s*>/i;
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

  const reasonLines = [
    `\`<task-complete/>\`${hasPhrase ? " (via fallback phrase — prefer the explicit marker)" : ""} emitted but required completion skills were not invoked this task:`,
    ...missing.map((m) => `  - \`${m.skill}\` — ${m.reason}`),
    "",
    "Invoke each missing skill (e.g. `$pre-commit`), then re-emit `<task-complete/>` on its own line.",
  ];
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
