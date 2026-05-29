import { readFileSync, existsSync } from "node:fs";

export type TaskScope = {
  hasCompletionSignal: boolean;
  markerKind: "marker" | "phrase" | null;
  lastAssistantText: string;
  editWriteCount: number;
  filesModified: Set<string>;
  durationMs: number;
  skillsInvoked: Set<string>;
};

export type Requirement = { skill: string; reason: string };

const MARKER_RE = /<task-complete\s*\/?\s*>/i;

const FALLBACK_PHRASES: RegExp[] = [
  /\btask\s+complete(?:d|ly)?\b/i,
  /\ball\s+done\b/i,
  /\bready\s+to\s+commit\b/i,
  /\ball\s+tests?\s+pass(?:ing)?\b/i,
  /\bwork\s+is\s+finished\b/i,
];

const EDIT_TOOL_NAMES = new Set(["Edit", "Write", "NotebookEdit"]);

const RETRO_THRESHOLDS = {
  edits: 3,
  files: 3,
  durationMs: 10 * 60 * 1000,
};

export function loadTranscript(path: string | undefined | null): any[] {
  if (!path || !existsSync(path)) return [];
  return readFileSync(path, "utf8")
    .split("\n")
    .filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } })
    .filter((x) => x !== null);
}

function assistantText(entry: any): string {
  const blocks = entry?.message?.content;
  if (!Array.isArray(blocks)) return "";
  return blocks
    .filter((b: any) => b?.type === "text" && typeof b.text === "string")
    .map((b: any) => b.text)
    .join("");
}

export function analyseTranscript(entries: any[]): TaskScope {
  const scopeStart = findScopeStart(entries);
  const inScope = entries.slice(scopeStart);

  const lastAssistantText = findLastAssistantText(inScope);

  const hasMarker = MARKER_RE.test(lastAssistantText);
  const hasPhrase = !hasMarker && FALLBACK_PHRASES.some((re) => re.test(lastAssistantText));
  const markerKind: TaskScope["markerKind"] = hasMarker ? "marker" : hasPhrase ? "phrase" : null;

  const { editWriteCount, filesModified, skillsInvoked } = collectToolUses(inScope);
  const durationMs = computeDuration(inScope);

  return {
    hasCompletionSignal: markerKind !== null,
    markerKind,
    lastAssistantText,
    editWriteCount,
    filesModified,
    durationMs,
    skillsInvoked,
  };
}

function findScopeStart(entries: any[]): number {
  for (let i = entries.length - 2; i >= 0; i--) {
    const e = entries[i];
    if (e?.type !== "assistant") continue;
    if (MARKER_RE.test(assistantText(e))) return i + 1;
  }
  return 0;
}

function findLastAssistantText(entries: any[]): string {
  for (let i = entries.length - 1; i >= 0; i--) {
    if (entries[i]?.type !== "assistant") continue;
    const text = assistantText(entries[i]);
    if (text) return text;
  }
  return "";
}

function collectToolUses(entries: any[]) {
  let editWriteCount = 0;
  const filesModified = new Set<string>();
  const skillsInvoked = new Set<string>();
  for (const e of entries) {
    if (e?.type !== "assistant") continue;
    const blocks = e?.message?.content;
    if (!Array.isArray(blocks)) continue;
    for (const b of blocks) {
      if (b?.type !== "tool_use") continue;
      if (EDIT_TOOL_NAMES.has(b.name)) {
        editWriteCount++;
        const fp = b.input?.file_path;
        if (typeof fp === "string" && fp) filesModified.add(fp);
      } else if (b.name === "Skill") {
        const s = b.input?.skill;
        if (typeof s === "string" && s) skillsInvoked.add(s);
      }
    }
  }
  return { editWriteCount, filesModified, skillsInvoked };
}

function computeDuration(entries: any[]): number {
  const ts: number[] = [];
  for (const e of entries) {
    const t = e?.timestamp;
    if (typeof t === "string") {
      const ms = Date.parse(t);
      if (!Number.isNaN(ms)) ts.push(ms);
    }
  }
  if (ts.length < 2) return 0;
  return Math.max(...ts) - Math.min(...ts);
}

export function requiredSkills(scope: TaskScope): Requirement[] {
  const req: Requirement[] = [];
  if (scope.editWriteCount > 0) {
    req.push({ skill: "pre-commit", reason: "Edit/Write ran this task" });
    req.push({ skill: "boochtek:documentation", reason: "Edit/Write ran this task" });
  }
  if (
    scope.editWriteCount >= RETRO_THRESHOLDS.edits ||
    scope.filesModified.size >= RETRO_THRESHOLDS.files ||
    scope.durationMs >= RETRO_THRESHOLDS.durationMs
  ) {
    req.push({ skill: "retro", reason: "task crossed effort threshold" });
  }
  return req;
}

export function missingRequiredSkills(scope: TaskScope): Requirement[] {
  return requiredSkills(scope).filter((r) => !wasSkillInvoked(r.skill, scope.skillsInvoked));
}

function wasSkillInvoked(required: string, invoked: Set<string>): boolean {
  const requiredBare = required.split(":").pop();
  for (const inv of invoked) {
    if (inv === required) return true;
    if (inv.split(":").pop() === requiredBare) return true;
  }
  return false;
}
